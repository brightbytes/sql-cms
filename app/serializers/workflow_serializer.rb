class WorkflowSerializer < ActiveModel::Serializer

  attributes :id, :name, :slug, :emails_to_notify, :ordered_transform_groups

  class TransformSerializer < ActiveModel::Serializer

    class TransformValidationSerializer < ActiveModel::Serializer


      class ValidationSerializer < ActiveModel::Serializer
        # HMM, THIS NESTING IS LAME.  MAYBE RETHINK.
      end
    end
  end

  has_many :data_quality_reports

  class DataQualityReportSerializer < ActiveModel::Serializer

    attributes :name, :params, :sql

  end


end
