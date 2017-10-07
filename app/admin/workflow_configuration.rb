ActiveAdmin.register WorkflowConfiguration do

  menu priority: 15

  actions :all

  permit_params :workflow_id, :customer_id, :redshift, :s3_region_name, :s3_bucket_name, :s3_file_path, notified_user_ids: []

  filter :workflow, as: :select, collection: proc { Workflow.order(:slug).all }
  filter :customer, as: :select, collection: proc { Customer.order(:slug).all }
  filter :s3_region_name, as: :select
  filter :s3_bucket_name, as: :select
  filter :s3_file_path, as: :select
  filter :redshift_unload_options, as: :string

  # This is necessary to disable default order by id
  config.sort_order = ''

  index(download_links: false) do
    column(:workflow_configuration, sortable: 'workflows.slug,customers.slug') do |workflow_configuration|
      text_node(auto_link(workflow_configuration))
      text_node('&nbsp;&nbsp;&nbsp;|&nbsp;&nbsp;&nbsp;'.html_safe)
      text_node(link_to("Edit", edit_workflow_configuration_path(workflow_configuration)))
    end
    column(:workflow, sortable: 'workflows.slug')
    column(:customer, sortable: 'customers.slug')
    boolean_column(:redshift)
    column(:last_run_status) { |workflow_configuration| human_status(workflow_configuration.runs.order(:id).last) }
    column('') do |workflow_configuration|
      if workflow_configuration.runs.count > 0
        text_node("Nuke All Runs to Delete")
      else
        link_to(
          "Delete",
          workflow_configuration_path(workflow_configuration),
          method: :delete,
          data: { confirm: 'Are you really sure you want to nuke this Workflow Configuration?' }
        )
      end
    end
  end

  show do
    attributes_table do
      row :id

      row :workflow
      row :customer

      row :redshift
      row :redshift_unload_options if resource.redshift?

      row :s3_region_name
      row :s3_bucket_name
      row :s3_file_path

      row :created_at
      row :updated_at
    end

    render partial: 'admin/workflow/run_panel',
           locals: { panel_name: 'Runs', runs: resource.runs.order(id: :desc).to_a }

    notifications = resource.notifications.joins(:user).order('users.first_name, users.last_name').to_a
    unless notifications.empty?
      panel 'Run Notifications' do
        table_for(notifications) do
          column(:user) { |notification| auto_link(notification.user) }
          column('Send an Email') { |notification| mail_to(notification.user.email) }
          column(:action) do |notification|
            link_to("Delete", notification_path(notification), method: :delete, data: { confirm: 'Are you sure you want to nuke this Notification?' })
          end
        end
      end
    end

    active_admin_comments

    render partial: 'admin/shared/history'
  end

  sidebar("Actions", only: :show) do
    ul do
      li link_to("Run Now", run_workflow_configuration_path(resource), method: :put)
      li link_to("Add New Run Notifications", edit_workflow_configuration_path(resource))
    end
  end

  config.add_action_item(
    :run_workflow_configuration,
    only: :show,
    if: proc { resource.workflow.transforms.count + resource.workflow.workflow_data_quality_reports.count > 0 }
  ) { link_to("Run Now", run_workflow_configuration_path(resource), method: :put) }

  member_action :run, method: :put do
    run = resource.run!(current_user)
    flash[:notice] = "Run generated."
    redirect_to run_path(run)
  end

  form do |f|
    # For debugging:
    # semantic_errors *f.object.errors.keys

    inputs 'Details' do
      input :customer, as: :select, collection: customers_with_single_select, include_blank: !customer_id_from_param
      input :workflow, as: :select, collection: workflows_with_single_select, include_blank: !workflow_id_param_val

      input :redshift, as: :select, include_blank: false
      input :redshift_unload_options, as: :string

      input :s3_region_name, as: :string # This should be a drop-down
      input :s3_bucket_name, as: :string
      input :s3_file_path, as: :string
    end

    inputs 'Run Notifications' do
      # The preselect doesn't work, for obvious reasons
      input :notified_users, as: :check_boxes, collection: User.all.order('users.first_name, users.last_name')
    end

    actions do
      action(:submit)
      path =
        if params[:source] == 'customer'
          customer_path(params[:customer_id])
        elsif params[:source] == 'workflow'
          customer_path(params[:workflow_id])
        elsif f.object.new_record?
          workflow_configurations_path
        else
          workflow_configuration_path(f.object)
        end
      cancel_link(path)
    end
  end

  controller do

    def scoped_collection
      super.includes(:customer, :workflow).order('workflows.slug, customers.slug')
    end

    def destroy
      if resource.runs.present?
        flash[:error] = "You must manually delete all associated Runs before deleting this WorkflowConfiguration."
        # This no-workie:
        # return redirect_to(:back)
        return redirect_to(workflow_configuration_path(resource))
      end
      super do |success, failure|
        success.html do
          path =
            if params[:source] == 'customer'
              customer_path(resource.customer)
            elsif params[:source] == 'workflow'
              workflow_path(resource.workflow)
            else
              workflow_configurations_path
            end
          redirect_to(path)
        end
      end
    end

  end
end
