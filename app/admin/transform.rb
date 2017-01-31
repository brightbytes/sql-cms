ActiveAdmin.register Transform do

  menu priority: 30

  actions :all

  permit_params :name, :runner, :workflow_id, :params_yaml, :sql, :transcompiled_source, :transcompiled_source_language, :data_file_id

  filter :name, as: :string
  filter :runner, as: :select, collection: Transform::RUNNERS
  filter :workflow, as: :select, collection: proc { Workflow.order(:slug).all }
  filter :sql, as: :string
  filter :transcompiled_source_language, as: :select, collection: Transform::TRANSCOMPILED_LANGUAGES
  filter :transcompiled_source, as: :string
  filter :data_file, as: :select, collection: proc { DataFile.order(:name).all }

  config.sort_order = 'workflows.slug_asc,name_asc'

  index(download_links: false) do
    column(:name) { |transform| auto_link(transform) }
    column(:workflow, sortable: 'workflows.slug')
    column(:customer, sortable: 'customers.slug')
    column(:runner)
  end

  show do
    attributes_table do
      row :id
      row :name
      row :workflow
      row :customer

      row :runner
      row(:params) { code(pretty_print_as_json(resource.params)) }
      row(:sql) { code(resource.sql) }
      row :transcompiled_source_language
      row(:transcompiled_source) { code(resource.transcompiled_source) }
      row :data_file

      row :copied_from_transform
      row :created_at
      row :updated_at
    end

    active_admin_comments

    render partial: 'admin/shared/history'
  end

  form do |f|
    inputs 'Details' do
      input :workflow_id, as: :hidden, input_html: { value: workflow_id_param_val }
      input :workflow, as: :select, collection: workflows_with_preselect(editing), input_html: { disabled: editing }

      input :name, as: :string
      input :runner, as: :select, collection: Transform::RUNNERS

      # FIXME - IT'S REALLY TOO BAD THIS LINE CAN'T BE MADE TO WORK LIKE THIS: https://lorefnon.me/2015/03/02/dealing-with-json-fields-in-active-admin.html
      #         (I TRIED, AND FAILED: DOESN'T WORK IN THE LATEST VERSION OF AA)
      input :params_yaml, as: :text

      input :sql, as: :text

      # Not ready for these yet
      # input :transcompiled_source_language, as: :select, collection: Transform::TRANSCOMPILED_LANGUAGES
      # input :transcompiled_source, as: :text

      input :data_file, as: :select, collection: data_files_for_workflow
    end
    actions do
      action(:submit)
      cancel_link(f.object.new_record? ? transforms_path : transform_path(f.object))
    end
  end

  controller do

    def scoped_collection
      super.joins(workflow: :customer)
    end

  end


end
