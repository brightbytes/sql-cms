ActiveAdmin.register WorkflowDataQualityReport do

  menu false

  actions :all, except: :index

  permit_params :workflow_id, :data_quality_report_id, :params_yaml, :enabled

  show title: :interpolated_name do
    attributes_table do
      row :id
      row :workflow
      row :data_quality_report
      row :interpolated_name if resource.params.present? && resource.name != resource.interpolated_name
      boolean_row :enabled
      code_format_row(:params_yaml)
      code_format_row(:workflow_params_yaml)
      code_format_row(:sql)
      code_format_row(:interpolated_sql) if resource.sql != resource.interpolated_sql
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

      input :params_yaml, as: :text

      input :workflow_params_yaml, as: :text, collection: resource.workflow.params_yaml, input_html: { disabled: true, rows: 4 }, hint: "These params will be reverse-merged into the params_yaml in the previous field: there's no need to type them again."

      input :enabled, hint: "Unchecking this causes this TransformValidation to be skipped during a Run "
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
        success.html { redirect_to(params[:source] == 'data_quality_report' ? data_quality_report_path(resource.data_quality_report) : parent_workflow_path) }
      end
    end
  end

end
