ActiveAdmin.register Run do

  menu priority: 60

  actions :index, :show, :destroy

  permit_params :immutable

  filter :customer, as: :select, collection: proc { Customer.order(:slug).all }
  filter :workflow, as: :select, collection: proc { Workflow.order(:slug).all }
  filter :creator, as: :select, collection: proc { User.order(:first_name, :last_name).all }
  filter :immutable

  config.sort_order = 'created_at_desc'

  index(download_links: false) do
    column(:schema_name, sortable: 'schema_name') { |run| auto_link(run) }
    column(:workflow_configuration)
    column(:workflow, sortable: 'workflows.slug')
    column(:customer, sortable: 'customers.slug')
    boolean_column(:immutable)
    column(:status) { |run| human_status(run) }
    column(:created_at)
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
      boolean_row :immutable

      row(:human_status) { human_status(resource) }
      row(:human_notification_status) { human_notification_status(resource) }

      row :status

      row :creator

      row(:duration) { human_duration(resource) }

      row :created_at
      row :updated_at
    end

    panel 'Run Step Logs' do
      sort = params[:order].try(:gsub, '_asc', ' ASC').try(:gsub, '_desc', ' DESC') || :name
      table_for(resource.run_step_logs.order('id'), sortable: true) do
        column(:step_name, sortable: :step_type) { |log| auto_link(log) }
        column(:human_status) { |log| human_status(log) }
        column(:duration) { |log| human_duration(log) }
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

  config.add_action_item :dump_schema, only: :show, if: proc { !resource.running_or_crashed? } do
    link_to("Dump Schema", dump_schema_run_path(resource), method: :put)
  end

  member_action :dump_schema, method: :put do
    send_data resource.schema_dump, filename: "#{resource.schema_name}.sql"
  end

  config.add_action_item :dump_execution_plan, only: :show, if: proc { !resource.running_or_crashed? } do
    link_to("Dump Execution Plan", dump_execution_plan_run_path(resource), method: :put)
  end

  member_action :dump_execution_plan, method: :put do
    # The screwing-around with `\\r?\\n` is so that multi-line JSON attribute values end up being broken into multiple lines in the display
    send_data JSON.pretty_generate(resource.execution_plan).gsub(/(.+)"(.+\\r?\\n)/, '\1"\\r\\n\2').gsub(/\\r?\\n/, "\n"), filename: "#{resource.schema_name}.json"
  end

  config.add_action_item :make_immutable, only: :show, if: proc { !resource.immutable? } do
    link_to("Make Undeletable", make_immutable_run_path(resource), method: :put)
  end

  member_action :make_immutable, method: :put do
    resource.immutable = true
    resource.save!
    flash[:notice] = "This Run is now immutable"
    if params[:source] = 'workflow_configuration'
      redirect_to workflow_configuration_path(resource.workflow_configuration)
    else
      redirect_to run_path(resource)
    end
  end

  config.add_action_item :make_mutable, only: :show, if: proc { resource.immutable? } do
    link_to("Make Deletable", make_mutable_run_path(resource), method: :put)
  end

  member_action :make_mutable, method: :put do
    resource.immutable = false
    resource.save!
    flash[:notice] = "This Run is now mutable"
    redirect_to run_path(resource)
  end

  config.add_action_item :destroy_run, only: :show, if: proc { resource.running_or_crashed? } do
    msg = "***This workflow is still running***, though it may have crashed. Are you sure you want to nuke this Run and all DB data associated with it?"
    link_to "Delete Run", { action: :destroy }, method: :delete, data: { confirm: msg }
  end

  # config.add_action_item :nuke_failed_steps_and_rerun, only: :show, if: proc { resource.failed? } do
  #   link_to(
  #     "Nuke Failed Steps and Rerun",
  #     nuke_failed_steps_and_rerun_run_path(resource),
  #     method: :put,
  #     data: { confirm: 'This will rerun with the same execution_plan, and thus is only useful for system-wide exceptions or validation failures you fixed directly in the DB.  Proceed?' }
  #   )
  # end

  # # This is only useful for dev debugging
  # member_action :nuke_failed_steps_and_rerun, method: :put do
  #   resource.nuke_failed_steps_and_rerun!
  #   flash[:notice] = "Failured steps nuked; rerunning from that point onward ..."
  #   redirect_to run_path(resource)
  # end

  controller do

    def scoped_collection
      super.includes(:creator, :customer, :workflow)
    end

    def action_methods
      result = super
      result -= ['destroy'] if action_name == 'show' && (resource.running_or_crashed? || resource.immutable?)
      result
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
