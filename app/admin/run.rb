ActiveAdmin.register Run do

  menu priority: 60

  actions :index, :show, :destroy

  filter :workflow, as: :select, collection: proc { Workflow.order(:slug).all }
  filter :creator, as: :select, collection: proc { User.order(:first_name, :last_name).all }
  filter :status, as: :string

  config.sort_order = 'workflows.slug_asc,id_asc'

  index(download_links: false) do
    column(:schema_name, sortable: 'schema_name') { |run| auto_link(run) }
    column(:workflow, sortable: 'workflows.slug')
    column(:customer, sortable: 'customers.slug')
    column(:creator, sortable: 'users.first_name,users.last_name')
    column(:human_status) { |run| human_status(run) }
  end

  show do
    attributes_table do
      row :id
      row(:schema_name) do
        text_node("<span style='color: blue'>SET search_path TO</span> <span style='color: red'>#{resource.schema_name}</span><span style='color: blue'>,public</span>".html_safe)
      end
      row :workflow
      row :customer
      row(:human_status) { human_status(resource) }
      row :status
      row :creator
      row :created_at
      row :updated_at
    end

    active_admin_comments

    panel 'Run Step Logs' do
      sort = params[:order].try(:gsub, '_asc', ' ASC').try(:gsub, '_desc', ' DESC') || :name
      table_for(resource.run_step_logs.order('id'), sortable: true) do
        column(:step_name, sortable: :step_type) { |log| auto_link(log) }
        column(:human_status) { |log| human_status(log) }
        column(:json_output) do |log|
          code(pretty_print_as_json(log.step_validation_failures.presence || log.step_exceptions.presence || log.step_result.presence))
        end
        # column(:step_plan) { |log| code(pretty_print_as_json(sql_newlines_to_array(log.step_plan))) }
      end
    end

    attributes_table do
      row(:execution_plan) { code(pretty_print_as_json(resource.execution_plan)) }
    end

    render partial: 'admin/shared/history'
  end


  controller do

    def scoped_collection
      super.joins(:creator, { workflow: :customer })
    end

    def destroy
      super do |success, failure|
        success.html do
          redirect_to(workflow_path(resource.workflow))
        end
      end
    end

  end

end
