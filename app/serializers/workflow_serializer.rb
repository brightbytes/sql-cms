class WorkflowSerializer < ActiveModel::Serializer

  # Bloody hell: it's not serializing the Transforms in :ordered_transform_groups ... grrrrrrrrr
  attributes :id, :name, :slug, :emails_to_notify, :ordered_transform_groups

  class TransformSerializer < ActiveModel::Serializer

    attributes :id, :name, :runner, :params, :sql

    belongs_to :data_file

    class TransformValidationSerializer < ActiveModel::Serializer

      attributes :name, :params, :sql

    end

    class DataFileSerializer < ActiveModel::Serializer

      attributes :name, :metadata, :file_type, :s3_region_name, :s3_bucket_name, :s3_file_name

    end
  end

  has_many :data_quality_reports

  class DataQualityReportSerializer < ActiveModel::Serializer

    attributes :name, :params, :sql

  end


end
