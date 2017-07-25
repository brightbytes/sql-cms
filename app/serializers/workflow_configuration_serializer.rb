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
#  redshift       :boolean          default(FALSE), not null
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

# Serializer for the Run#execution_plan-relevant attributes of a WorkflowConfiguration, and all subsidiary objects.
# Tested somewhat indirectly via the Run spec ... which is good enough, IMO

class WorkflowConfigurationSerializer < ActiveModel::Serializer

  attributes :id, :workflow_id, :customer_id, :s3_region_name, :s3_bucket_name, :s3_file_path, :rfc_email_addresses_to_notify, :name, :slug

  attribute :ordered_transform_groups do
    # Totally ghetto: this should be automatic.  Bah.
    object.ordered_transform_groups.map { |set| set.map { |transform| ActiveModelSerializers::SerializableResource.new(transform).as_json }  }
  end

  has_many :workflow_data_quality_reports

end

class WorkflowDataQualityReportSerializer < ActiveModel::Serializer

  attributes :id, :params, :name, :interpolated_name, :sql, :interpolated_sql

end

class TransformSerializer < ActiveModel::Serializer

  attributes :id, :name, :interpolated_name, :runner, :params, :sql, :interpolated_sql, :s3_file_name

  has_many :transform_validations

end

class TransformValidationSerializer < ActiveModel::Serializer

  attributes :id, :params, :name, :interpolated_name, :sql, :interpolated_sql

end
