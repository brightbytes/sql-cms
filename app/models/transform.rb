# == Schema Information
#
# Table name: public.transforms
#
#  id           :integer          not null, primary key
#  name         :string           not null
#  runner       :string           default("Sql"), not null
#  workflow_id  :integer          not null
#  sql          :text             not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  params       :jsonb
#  s3_file_name :string
#
# Indexes
#
#  index_transforms_on_lowercase_name  (lower((name)::text)) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (workflow_id => workflows.id)
#

class Transform < ApplicationRecord

  include Concerns::ParamsHelpers

  auto_normalize except: :sql

  # Validations

  validates :sql, :workflow, presence: true

  validates :name, presence: true, uniqueness: { case_sensitive: false }

  validates :runner, presence: true, inclusion: { in: RunnerFactory::RUNNERS }

  JOINED_S3_FILE_RUNNERS = RunnerFactory::S3_FILE_RUNNERS.join(',').freeze
  S3_ATTRIBUTES_PRESENT_ERROR_MSG = "is required for runners of type: #{JOINED_S3_FILE_RUNNERS}".freeze

  validates :s3_file_name, presence: { message: S3_ATTRIBUTES_PRESENT_ERROR_MSG }, if: :s3_file_required?

  before_validation :clear_s3_attribute, unless: :s3_file_required?

  private def clear_s3_attribute
    self.s3_file_name = nil
  end

  before_validation :add_placeholder_sql, if: :auto_load?

  private def add_placeholder_sql
    self.sql = "-- To be dynamically generated by the AutoLoad Runner" unless sql.present?
  end

  # FIXME - GET RID OF THIS UGLY CRAP HACK, PER FUTURE PLANS DOC
  before_validation :maybe_generate_default_sql, if: :copy_from?

  DEFAULT_TSV_SQL = %q{COPY :table_name FROM STDIN WITH DELIMITER E'\t' NULL ''}
  DEFAULT_CSV_SQL = "COPY :table_name FROM STDIN WITH CSV"

  def maybe_generate_default_sql
    if sql.blank?
      self.sql = DEFAULT_TSV_SQL if s3_import_file.tsv?
      self.sql = DEFAULT_CSV_SQL if s3_import_file.csv?
    end
  end

  # Associations

  belongs_to :workflow, inverse_of: :transforms

  has_many :workflow_configurations, through: :workflow

  has_many :prerequisite_dependencies, class_name: 'TransformDependency', foreign_key: :postrequisite_transform_id, dependent: :delete_all
  has_many :prerequisite_transforms, through: :prerequisite_dependencies, source: :prerequisite_transform

  has_many :postrequisite_dependencies, class_name: 'TransformDependency', foreign_key: :prerequisite_transform_id, dependent: :delete_all
  has_many :postrequisite_transforms, through: :postrequisite_dependencies, source: :postrequisite_transform

  has_many :transform_validations, inverse_of: :transform, dependent: :delete_all
  has_many :validations, through: :transform_validations

  # Scopes

  scope :importing, -> { where(runner: RunnerFactory::IMPORT_S3_FILE_RUNNERS) }

  scope :exporting, -> { where(runner: RunnerFactory::EXPORT_S3_FILE_RUNNERS) }

  scope :file_related, -> { where(runner: RunnerFactory::S3_FILE_RUNNERS) }

  scope :non_file_related, -> { where(runner: RunnerFactory::NON_S3_FILE_RUNNERS) }

  scope :independent, -> { where("NOT EXISTS (SELECT 1 FROM transform_dependencies WHERE postrequisite_transform_id = transforms.id)") }

  scope :dependent, -> { where("EXISTS (SELECT 1 FROM transform_dependencies WHERE postrequisite_transform_id = transforms.id)") }

  # Instance Methods

  concerning :Runners do

    def importing?
      runner.in?(RunnerFactory::IMPORT_S3_FILE_RUNNERS)
    end

    def exporting?
      runner.in?(RunnerFactory::EXPORT_S3_FILE_RUNNERS)
    end

    def s3_file_required?
      runner.in?(RunnerFactory::S3_FILE_RUNNERS)
    end

    def auto_load?
      runner == 'AutoLoad'
    end

    def copy_from?
      runner == 'CopyFrom'
    end

  end

  concerning :S3Files do

    def s3_file_name
      self.class.interpolate(string: super, params: params)
    end

    def s3_import_file(workflow_config = nil)
      S3File.create('import', **s3_attributes(workflow_config)) if importing?
    end

    # Not currently used.  Probably unnecessary ... though, hmm, perhaps useful off the Run object and a Likely Transform for a quick local download?
    # def s3_export_file(run:, workflow_config: )
    #   S3File.create('export', **s3_attributes(workflow_config).merge(run: run)) if exporting?
    # end

    private def s3_attributes(workflow_config)
      attributes.with_indifferent_access.slice(:s3_file_name).tap do |h|
        h.merge(workflow_config.attributes.with_indifferent_access.slice(:s3_region_name, :s3_bucket_name, :s3_file_path)) if workflow_config
      end.symbolize_keys
    end

  end

  concerning :EligiblePrerequisiteTransforms do

    included do
      accepts_nested_attributes_for :prerequisite_transforms
    end

    # Any Transform that doesn't directly or indirectly have this Transform as a prerequisite is itself available as a prerequisite (and may already be such).
    # This is how we avoid cycles in the Transform Dependency graph.
    def available_prerequisite_transforms
      base_arel = Transform.where(workflow_id: workflow_id).order(:name)
      if new_record?
        base_arel.all
      else
        # This is grossly inefficient.  I tried to do it with SQL for the first level, and failed.  Oh well.  Refactor later.
        eligible_transforms = base_arel.where("id <> #{id}").all
        # Where's that graph DB when you need it?
        eligible_transforms.reject { |eligible_transform| already_my_postrequisite?(eligible_transform) }
      end
    end

    # Any Transform that doesn't directly or indirectly have this Transform as a prerequisite and is not already a prerequisite of this Transform
    #  is itself available as a new prerequisite.
    # Turns out we may not need this method; only #available_prerequisite_transforms is in fact necessary
    # def available_unused_prerequisite_transforms
    #   available_prerequisite_transforms.reject { |eligible_transform| already_my_prerequisite?(eligible_transform) }
    # end

    private

    def already_my_postrequisite?(transform)
      dependents = transform.prerequisite_transforms
      return false if dependents.empty?
      return true if dependents.include?(self)
      dependents.any? { |dependent_transform| already_my_postrequisite?(dependent_transform) }
    end

    # def already_my_prerequisite?(transform)
    #   dependents = transform.postrequisite_transforms
    #   return false if dependents.empty?
    #   return true if dependents.include?(self)
    #   dependents.any? { |dependent_transform| already_my_prerequisite?(dependent_transform) }
    # end

  end

end
