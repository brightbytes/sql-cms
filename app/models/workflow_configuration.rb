# == Schema Information
#
# Table name: workflow_configurations
#
#  id             :integer          not null, primary key
#  workflow_id    :integer          not null
#  s3_region_name :string           not null
#  s3_bucket_name :string           not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  customer_id    :integer
#  s3_file_path   :string
#
# Indexes
#
#  index_unique_workflow_configurations_on_workflow_customer  (workflow_id,customer_id) UNIQUE
#  index_workflow_configurations_on_customer_id               (customer_id)
#
# Foreign Keys
#
#  fk_rails_...  (customer_id => customers.id)
#  fk_rails_...  (workflow_id => workflows.id)
#

class WorkflowConfiguration < ApplicationRecord

  auto_normalize

  # Validations

  validates :workflow, presence: true, uniqueness: { scope: :customer_id }

  validates :s3_region_name, :s3_bucket_name, presence: true

  # FIXME - We may reuse this and its partner callback in WorkflowConfig ... but not right now
  # validate :supplied_s3_url_is_not_hosed, if: :s3_file_specified_by_url?
  # private def supplied_s3_url_is_not_hosed
  #   if supplied_s3_url.blank?
  #     errors.add(:supplied_s3_url, "must be provided")
  #   else
  #     if s3_file_name.blank?
  #       errors.add(:supplied_s3_url, "is not a valid S3 URL")
  #     else
  #       errors.add(:supplied_s3_url, "specifies a different S3 region than the Workflow") unless @parsed_s3_region_name == workflow.s3_region_name
  #       errors.add(:supplied_s3_url, "specifies a different S3 bucket than the Workflow") unless @parsed_s3_bucket_name == workflow.s3_bucket_name
  #     end
  #   end
  # end

  # Callbacks

  # FIXME - We may reuse this and its partner validation in WorkflowConfig ... but not right now
  # before_validation :parse_supplied_s3_url, if: :s3_file_specified_by_url?
  # private def parse_supplied_s3_url
  #   if supplied_s3_url.present?
  #     http_match = %r{\Ahttp(?:s)?://s3-([-\w]+).amazonaws.com/([-\w]+)/(.{10,})\Z}.match(supplied_s3_url)
  #     if http_match
  #       @parsed_s3_region_name = http_match[1]
  #       @parsed_s3_bucket_name = http_match[2]
  #       file_path_and_name = http_match[3].split('/').reject(&:blank?)
  #       self.s3_file_path = file_path_and_name[0..-2].join('/') unless file_path_and_name.size == 1
  #       self.s3_file_name = file_path_and_name.last
  #     end
  #   end
  # end

  # Associations

  belongs_to :customer, inverse_of: :workflow_configurations
  belongs_to :workflow, inverse_of: :workflow_configurations

  # Instance Methods

  def to_s
    prefix = customer&.slug || "shared"
    suffix = workflow&.slug || "unsaved_workflow"
    "#{prefix}_#{suffix}".freeze
  end

  # FIXME - We may reuse this in Workflow ... but not right now
  # attr_accessor :specify_s3_file_by, :supplied_s3_url

  # FIXME - We may reuse this in Workflow ... but not right now
  # def s3_file_specified_by_url?
  #   s3_file_required? && specify_s3_file_by == 'url'
  # end

end
