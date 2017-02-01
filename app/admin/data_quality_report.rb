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
      row(:sql) { code(resource.sql) }

      row :copied_from_data_quality_report

      row :created_at
      row :updated_at
    end

    active_admin_comments

    render partial: 'admin/shared/history'
  end

  form do |f|
    inputs 'Details' do
      editing = action_name.in?(%w(edit update))
      input :customer_id, as: :hidden, input_html: { value: transform_customer_id_param_val }
      input :workflow_id, as: :hidden, input_html: { value: workflow_id_param_val }
      input :workflow, as: :select, collection: workflows_with_preselect(editing), input_html: { disabled: editing }

      input :name, as: :string

      # FIXME - IT'S REALLY TOO BAD THIS LINE CAN'T BE MADE TO WORK LIKE THIS: https://lorefnon.me/2015/03/02/dealing-with-json-fields-in-active-admin.html
      #         (I TRIED, AND FAILED: DOESN'T WORK IN THE LATEST VERSION OF AA)
      input :params_yaml, as: :text

      input :sql, as: :text
    end

    actions do
      action(:submit)
      cancel_link(f.object.new_record? ? data_quality_reports_path : data_quality_report_path(f.object))
    end
  end

  controller do

    def scoped_collection
      super.joins(workflow: :customer)
    end

  end

end