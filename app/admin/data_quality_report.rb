ActiveAdmin.register DataQualityReport do

  menu priority: 50

  actions :all

  permit_params :name, :workflow_id, :params_yaml, :sql

  filter :name, as: :string
  filter :workflow, as: :select, collection: proc { Workflow.order(:slug).all }
  filter :sql, as: :string

  config.sort_order = 'workflows.slug_asc,name_asc'

  index(download_links: false) do
    column(:name) { |transform| auto_link(transform) }
    column(:workflow, sortable: 'workflows.slug')
    column(:customer, sortable: 'customers.slug')
  end

  show do
    attributes_table do
      row :id
      row :name
      row :workflow
      row :customer

      row(:params) { code(pretty_print_as_json(resource.params)) }
      simple_format_row(:sql)
      simple_format_row(:interpolated_sql) if resource.params.present?

      row :created_at
      row :updated_at
    end

    active_admin_comments

    render partial: 'admin/shared/history'
  end

  sidebar("Actions", only: :show) do
    ul do
      li link_to("Copy to Another Workflow")
    end
  end

  form do |f|
    inputs 'Details' do
      editing = action_name.in?(%w(edit update))
      input :customer_id, as: :hidden, input_html: { value: transform_customer_id_param_val }
      input :workflow_id, as: :hidden, input_html: { value: workflow_id_param_val }
      input :workflow, as: :select, collection: workflows_with_single_select, include_blank: params[:workflow_id].blank?, input_html: { disabled: editing }

      input :name, as: :string

      # FIXME - IT'S REALLY TOO BAD THIS LINE CAN'T BE MADE TO WORK LIKE THIS: https://lorefnon.me/2015/03/02/dealing-with-json-fields-in-active-admin.html
      #         (I TRIED, AND FAILED: DOESN'T WORK IN THE LATEST VERSION OF AA)
      input :params_yaml, as: :text

      input :sql, as: :text
    end

    actions do
      action(:submit)
      path = (params[:source] == 'workflow' ? workflow_path(params[:workflow_id]) : f.object.new_record? ? data_quality_reports_path : data_quality_report_path(f.object))
      cancel_link(path)
    end
  end

  controller do

    def scoped_collection
      super.joins(workflow: :customer)
    end

    def destroy
      super do |success, failure|
        success.html do
          redirect_to(params[:source] == 'workflow' ? workflow_path(resource.workflow) : data_quality_reports_path)
        end
      end
    end

  end

end
