# == Schema Information
#
# Table name: transforms
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
#  enabled      :boolean          default(TRUE), not null
#
# Indexes
#
#  index_transforms_on_lowercase_name_and_workflow_id  (lower((name)::text), workflow_id) UNIQUE
#  index_transforms_on_workflow_id                     (workflow_id)
#
# Foreign Keys
#
#  fk_rails_...  (workflow_id => workflows.id)
#

class Transform < ApplicationRecord

  include Concerns::EnabledDisabledMethods

  include Concerns::ParamsHelpers
  include Concerns::InterpolationHelpers

  auto_normalize except: :sql

  # Validations

  validates :sql, :workflow, presence: true

  validates :name, presence: true, uniqueness: { scope: :workflow_id, case_sensitive: false }

  RUNNERS = %w(RailsMigration AutoLoad CopyFrom Sql CopyTo Unload).freeze

  IMPORT_S3_FILE_RUNNERS = %w(AutoLoad CopyFrom).freeze
  EXPORT_S3_FILE_RUNNERS = %w(CopyTo Unload).freeze
  S3_FILE_RUNNERS = (IMPORT_S3_FILE_RUNNERS + EXPORT_S3_FILE_RUNNERS).freeze

  NON_S3_FILE_RUNNERS = %w(RailsMigration Sql).freeze

  validates :runner, presence: true, inclusion: { in: RUNNERS }

  JOINED_S3_FILE_RUNNERS = S3_FILE_RUNNERS.join(',').freeze
  S3_ATTRIBUTES_PRESENT_ERROR_MSG = "is required for runners of type: #{JOINED_S3_FILE_RUNNERS}".freeze

  validates :s3_file_name, presence: { message: S3_ATTRIBUTES_PRESENT_ERROR_MSG }, if: :s3_file_required?

  validate :table_name_param_present, if: :importing?

  def table_name_param_present
    # This really, really shouldn't be necessary b/c the params super does the with_indifferent_access ... but it is.  :-(
    table_name = params.with_indifferent_access[:table_name]
    errors.add(:params, "must specify a table_name") if table_name.blank?
  end

  # Callbacks

  before_validation :clear_s3_attribute, unless: :s3_file_required?

  private def clear_s3_attribute
    self.s3_file_name = nil
  end

  before_validation :maybe_add_placeholder_sql

  SQL_DYNAMICALLY_GENERATED_MSG = "-- To be dynamically generated by the Runner"

  private def maybe_add_placeholder_sql
    # We only do this when sql.blank? on the off chance the User entered something they don't want to have disappear.
    self.sql = SQL_DYNAMICALLY_GENERATED_MSG if sql.blank? && importing?
  end

  before_update :nuke_dependencies, if: :workflow_id_changed?

  private def nuke_dependencies # because the target Transforms are in the old Workflow
    prerequisite_dependencies.delete_all
    postrequisite_dependencies.delete_all
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

  scope :importing, -> { where(runner: IMPORT_S3_FILE_RUNNERS) }

  scope :exporting, -> { where(runner: EXPORT_S3_FILE_RUNNERS) }

  scope :rails_migration, -> { where(runner: 'RailsMigration') }

  scope :not_rails_migration, -> { where.not(runner: 'RailsMigration') }

  scope :file_related, -> { where(runner: S3_FILE_RUNNERS) }

  scope :non_file_related, -> { where(runner: NON_S3_FILE_RUNNERS) }

  scope :independent, -> { where("NOT EXISTS (SELECT 1 FROM transform_dependencies WHERE postrequisite_transform_id = transforms.id)") }

  scope :dependent, -> { where("EXISTS (SELECT 1 FROM transform_dependencies WHERE postrequisite_transform_id = transforms.id)") }

  # Instance Methods

  # Exclusively for the AA front-end.  Hate doing this, but it's the easiest way to preserve params across round trips.
  # I'm sure there's a better way in Rails today, but I'm apparently too lame to google it.
  attr_accessor :source

  def params
    # This allows reuse of, e.g., :table_name from the associated Workflow's #params
    (workflow&.params || {}).merge(super || {})
  end

  def workflow_params_yaml
    workflow&.params_yaml
  end

  def interpolated_s3_file_name
    self.class.interpolate(string: s3_file_name, params: params, quote_arrays: false)
  end

  def copy_to(new_workflow_or_workflow_id)
    new_workflow_id = (new_workflow_or_workflow_id.is_a?(Workflow) ? new_workflow_or_workflow_id.id : new_workflow_or_workflow_id)
    dup.tap do |new_transform|
      new_transform.workflow_id = new_workflow_id
      new_transform.save!
    end
  end

  concerning :Runners do

    def importing?
      runner&.in?(IMPORT_S3_FILE_RUNNERS)
    end

    def exporting?
      runner&.in?(EXPORT_S3_FILE_RUNNERS)
    end

    def s3_file_required?
      runner&.in?(S3_FILE_RUNNERS)
    end

    def auto_load?
      runner == 'AutoLoad'
    end

  end

  concerning :S3Files do

    def s3_import_file(workflow_config = nil)
      S3File.create('import', **s3_attributes(workflow_config)) if importing?
    end

    # Not currently used.  Probably unnecessary ... though, hmm, perhaps useful off the Run object and a Likely Transform for a quick local download?
    # def s3_export_file(run:, workflow_config: )
    #   S3File.create('export', **s3_attributes(workflow_config).merge(run: run)) if exporting?
    # end

    private def s3_attributes(workflow_config)
      attributes.with_indifferent_access.slice(:s3_file_name).tap do |h|
        h.merge!(workflow_config.attributes.with_indifferent_access.slice(:s3_region_name, :s3_bucket_name, :s3_file_path)) if workflow_config
      end.symbolize_keys
    end

  end

  # FIXME - Copy/paste to Workflow model; DRY up sometime
  concerning :EligiblePrerequisiteTransforms do

    included do
      accepts_nested_attributes_for :prerequisite_transforms
    end

    # Any Transform that doesn't directly or indirectly have this Transform as a prerequisite is itself available as a prerequisite (and may already be such).
    # This is how we avoid cycles in the Transform Dependency graph.
    # There has to be an algorithmic way to obtain the "Sibling groups" of a DAG starting from the leaf nodes and going up, as this does ... but couldn't find it
    def available_prerequisite_transforms
      base_arel = Transform.where(workflow_id: workflow_id).order(:name)
      if new_record?
        base_arel.all
      else
        eligible_transform_ids = base_arel.where("id <> #{id}").pluck(:id)
        Transform.where(id: eligible_transform_ids.reject { |eligible_transform_id| already_my_postrequisite?(eligible_transform_id) }).sort_by { |t| t.interpolated_name.downcase }
      end
    end

    private

    def already_my_postrequisite?(transform_id)
      dependent_ids = TransformDependency.where(postrequisite_transform_id: transform_id).pluck(:prerequisite_transform_id)
      return false if dependent_ids.empty?
      return true if dependent_ids.include?(id)
      dependent_ids.any? { |dependent_id| already_my_postrequisite?(dependent_id) }
    end

  end

end
