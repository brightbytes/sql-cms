
# == Schema Information
#
# Table name: public.workflows
#
#  id                      :integer          not null, primary key
#  name                    :string           not null
#  slug                    :string           not null
#  customer_id             :integer          not null
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#
# Indexes
#
#  index_workflows_on_customer_id              (customer_id)
#  index_workflows_on_lowercase_name           (lower((name)::text)) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (customer_id => customers.id)
#

# Serializer for the Run#execution_plan-relevant attributes of a Workflow, and all subsidiary objects.
# Tested somewhat indirectly via the Run spec ... which is good enough, IMO
class WorkflowSerializer < ActiveModel::Serializer

  attributes :id, :name, :slug, :emails_to_notify

  attribute :ordered_transform_groups do
    # Totally ghetto: this should be automatic.  Bah.
    object.ordered_transform_groups.map { |set| set.map { |transform| ActiveModelSerializers::SerializableResource.new(transform).as_json }  }
  end

  has_many :data_quality_reports
end


class DataQualityReportSerializer < ActiveModel::Serializer

  attributes :id, :name, :params, :sql

end

class TransformSerializer < ActiveModel::Serializer

  attributes :id, :name, :runner, :params, :sql

  belongs_to :data_file

  has_many :transform_validations

end

class DataFileSerializer < ActiveModel::Serializer

  attributes :id, :name, :file_type, :s3_region_name, :s3_bucket_name, :s3_file_path, :s3_file_name

end

class TransformValidationSerializer < ActiveModel::Serializer

  attributes :name, :params, :sql

end
