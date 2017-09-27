ActiveAdmin.register WorkflowDataQualityReport do

  menu false

  actions :all, except: :index

  permit_params :workflow_id, :data_quality_report_id, :params_yaml

  show title: :interpolated_name do
    attributes_table do
      row :id
      row :workflow
      row :data_quality_report
      row :interpolated_name if resource.params.present? && resource.name != resource.interpolated_name
      row(:params) { code(pretty_print_as_json(resource.params)) }
      simple_format_row(:sql)
      simple_format_row(:interpolated_sql) if resource.sql != resource.interpolated_sql
      row(:data_quality_report_immutable) { yes_no(resource.data_quality_report.immutable) }
      row :created_at
      row :updated_at
    end
  end

  form do |f|
    # For debugging:
    semantic_errors *f.object.errors.keys
    inputs 'Details' do
      input :workflow_id, as: :hidden, input_html: { value: workflow_id_param_val }
      input :workflow, as: :select, collection: [[resource_workflow.name, resource_workflow.id, selected: true]], input_html: { disabled: true }
      input :data_quality_report, as: :select, collection: DataQualityReport.order(:name).all

      input :params_yaml, as: :text, required: true
    end
    actions do
      action(:submit)
      cancel_link(parent_workflow_path)
    end
  end

  controller do

    def create
      super do |success, failure|
        success.html { redirect_to(parent_workflow_path) }
      end
    end

    def update
      super do |success, failure|
        success.html { redirect_to(parent_workflow_path) }
      end
    end

    def destroy
      super do |success, failure|
        success.html { redirect_to(parent_workflow_path) }
      end
    end
  end

end
