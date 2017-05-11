ActiveAdmin.register Run do

  menu priority: 60

  actions :index, :show, :destroy

  filter :customer, as: :select, collection: proc { Customer.order(:slug).all }
  filter :workflow, as: :select, collection: proc { Workflow.order(:slug).all }
  filter :creator, as: :select, collection: proc { User.order(:first_name, :last_name).all }
  filter :status, as: :string

  config.sort_order = 'id_desc'

  index(download_links: false) do
    column(:schema_name, sortable: 'schema_name') { |run| auto_link(run) }
    column(:workflow_configuration)
    column(:workflow, sortable: 'workflows.slug')
    column(:customer, sortable: 'customers.slug')
    column(:creator, sortable: 'users.first_name,users.last_name')
    column(:human_status) { |run| human_status(run) }
  end

  show do
    attributes_table do
      row :id

      row(:schema_name) do
        text_node("<span style='color: blue'>SET search_path TO</span> <span style='color: red'>#{resource.schema_name}</span>;".html_safe)
      end

      row :workflow_configuration
      row :workflow
      row :customer

      row(:human_status) { human_status(resource) }
      row(:human_notification_status) { human_notification_status(resource) }

      row :status

      row :creator

      row :created_at
      row :updated_at
    end

    panel 'Run Step Logs' do
      sort = params[:order].try(:gsub, '_asc', ' ASC').try(:gsub, '_desc', ' DESC') || :name
      table_for(resource.run_step_logs.order('id'), sortable: true) do
        column(:step_name, sortable: :step_type) { |log| auto_link(log) }
        column(:human_status) { |log| human_status(log) }
        column(:json_output) do |log|
          code(pretty_print_as_json(log.step_validation_failures.presence || log.step_exceptions.presence || log.step_result.presence))
        end
      end
    end

    attributes_table do
      row(:execution_plan) { code(pretty_print_as_json(resource.execution_plan)) }
    end

    active_admin_comments

    render partial: 'admin/shared/history'
  end

  config.add_action_item :nuke_failed_steps_and_rerun, only: :show, if: proc { resource.failed? } do
    link_to(
      "Nuke Failed Steps and Rerun",
      nuke_failed_steps_and_rerun_run_path(resource),
      method: :put,
      data: { confirm: 'This will rerun with the same execution_plan, and thus is only useful for system-wide exceptions or validation failures you fixed directly in the DB.  Proceed?' }
    )
  end

  # This is only useful for dev debugging
  member_action :nuke_failed_steps_and_rerun, method: :put do
    resource.nuke_failed_steps_and_rerun!
    flash[:notice] = "Failured steps nuked; rerunning from that point onward ..."
    redirect_to run_path(resource)
  end

  controller do

    def scoped_collection
      super.includes(:creator, :customer, :workflow)
    end

    def destroy
      super do |success, failure|
        success.html do
          redirect_to(workflow_configuration_path(resource.workflow_configuration))
        end
      end
    end

  end

end
