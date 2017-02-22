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
#  data_file_id :integer
#
# Indexes
#
#  index_transforms_on_data_file_id                  (data_file_id)
#  index_transforms_on_lowercase_name                (lower((name)::text)) UNIQUE
#  index_transforms_on_workflow_id_and_data_file_id  (workflow_id,data_file_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (data_file_id => data_files.id)
#  fk_rails_...  (workflow_id => workflows.id)
#

class Transform < ApplicationRecord

  include Concerns::ParamsHelpers

  auto_normalize except: :sql

  # Validations

  validates :sql, :workflow, presence: true

  validates :name, presence: true, uniqueness: { case_sensitive: false }

  validates :runner, presence: true, inclusion: { in: RunnerFactory::RUNNERS }

  validate :s3_attributes_present, if: :s3_file_required?

  JOINED_S3_FILE_RUNNERS = RunnerFactory::S3_FILE_RUNNERS.join(',').freeze
  S3_ATTRIBUTES_PRESENT_ERROR_MSG = "is required for runners of type: #{JOINED_S3_FILE_RUNNERS}".freeze

  def s3_attributes_present
    errors.add(:s3_region_name, S3_ATTRIBUTES_PRESENT_ERROR_MSG) if s3_region_name.blank?
    errors.add(:s3_bucket_name, S3_ATTRIBUTES_PRESENT_ERROR_MSG) if s3_bucket_name.blank?
    errors.add(:s3_file_name, S3_ATTRIBUTES_PRESENT_ERROR_MSG) if s3_file_name.blank?
  end

  validate :supplied_s3_url_is_not_hosed, if: :s3_file_required?

  private def supplied_s3_url_is_not_hosed
    errors.add(:supplied_s3_url, "must be provided") if supplied_s3_url.blank? && s3_bucket_name.blank? && s3_file_name.blank?
    errors.add(:supplied_s3_url, "is not a valid S3 URL") if supplied_s3_url.present? && s3_bucket_name.blank? && s3_file_name.blank?
  end

  # Callbacks

  after_initialize :set_defaults

  private def set_defaults
    if new_record?
      self.s3_region_name = ENV.fetch('DEFAULT_S3_REGION', 'us-west-2')
      self.s3_bucket_name = ENV['DEFAULT_S3_BUCKET']
    end
  end

  before_validation :parse_supplied_s3_url, if: :s3_file_required?

  private def parse_supplied_s3_url
    if supplied_s3_url.present?
      http_match = %r{\Ahttp(?:s)?://s3-([-\w]+).amazonaws.com/([-\w]+)/(.{10,})\Z}.match(supplied_s3_url)
      if http_match
        self.s3_region_name = http_match[1]
        self.s3_bucket_name = http_match[2]
        file_path_and_name = http_match[3].split('/').reject(&:blank?)
        self.s3_file_path = file_path_and_name[0..-2].join('/') unless file_path_and_name.size == 1
        self.s3_file_name = file_path_and_name.last
      end
    end
  end

  before_validation :clear_s3_attributes, unless: :s3_file_required?

  private def clear_s3_attributes
    self.s3_region_name = self.s3_bucket_name = self.s3_file_path = self.s3_file_name = self.supplied_s3_url = nil
  end

  # Associations

  belongs_to :workflow, inverse_of: :transforms

  has_one :customer, through: :workflow

  has_many :prerequisite_dependencies, class_name: 'TransformDependency', foreign_key: :postrequisite_transform_id, dependent: :delete_all
  has_many :prerequisite_transforms, through: :prerequisite_dependencies, source: :prerequisite_transform

  has_many :postrequisite_dependencies, class_name: 'TransformDependency', foreign_key: :prerequisite_transform_id, dependent: :delete_all
  has_many :postrequisite_transforms, through: :postrequisite_dependencies, source: :postrequisite_transform

  has_many :transform_validations, inverse_of: :transform, dependent: :delete_all
  has_many :validations, through: :transform_validations

  # Scopes

  scope :having_s3_import_file, -> { where(runner: RunnerFactory::IMPORT_S3_FILE_RUNNERS) }

  scope :having_s3_export_file, -> { where(runner: RunnerFactory::EXPORT_S3_FILE_RUNNERS) }

  scope :having_no_s3_file, -> { where(runner: RunnerFactory::NON_S3_FILE_RUNNERS) }

  # Instance Methods

  accepts_nested_attributes_for :prerequisite_transforms

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
  def available_unused_prerequisite_transforms
    available_prerequisite_transforms.reject { |eligible_transform| already_my_prerequisite?(eligible_transform) }
  end

  private

  def already_my_postrequisite?(transform)
    dependents = transform.prerequisite_transforms
    return false if dependents.empty?
    return true if dependents.include?(self)
    dependents.any? { |dependent_transform| already_my_postrequisite?(dependent_transform) }
  end

  def already_my_prerequisite?(transform)
    dependents = transform.postrequisite_transforms
    return false if dependents.empty?
    return true if dependents.include?(self)
    dependents.any? { |dependent_transform| already_my_prerequisite?(dependent_transform) }
  end

  public

  def s3_file_required?
    runner.in?(RunnerFactory::S3_FILE_RUNNERS)
  end

  attr_accessor :supplied_s3_url

  def s3_object(for_run = nil)
    return nil unless all_required_s3_fields_present?
    # FIXME - I'm not happy about how I did this method overloading for import and export file_types
    raise "You must supply a Run object for export files!" if export? && !for_run

    @s3_object ||
      begin
        s3_bucket = s3.bucket(s3_bucket_name)
        path = (export? ? "#{s3_file_path}/run_#{for_run.id}" : s3_file_path)
        @s3_object = s3_bucket.object("#{path}/#{s3_file_name}")
      end
  end

  def s3_presigned_url
    return false unless all_required_s3_fields_present?
    @s3_presigned_url ||= s3_object.presigned_url(:get) if s3_object.exists?
  end

  def s3_file_exists?
    import? && !!s3_presigned_url
  end

  def s3_public_url
    return false unless all_required_s3_fields_present?
    @s3_public_url ||= s3_object.public_url if s3_object.exists?
  end

  private

  def s3
    @s3 ||= Aws::S3::Resource.new(region: s3_region_name)
  end

  def all_required_s3_fields_present?
    [s3_region_name, s3_bucket_name, s3_file_name].all?(&:present?)
  end

end
