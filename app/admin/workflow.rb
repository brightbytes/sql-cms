ActiveAdmin.register Workflow do

  menu priority: 20

  actions :all

  permit_params :name, :customer_id, :slug, :shared, :s3_region_name, :s3_bucket_name, :s3_file_path, notified_user_ids: [], included_workflow_ids: []

  filter :name, as: :string
  filter :customer, as: :select, collection: proc { Customer.order(:slug).all }
  filter :shared, as: :select, collection: [["Yes", true], ["No", false]]
  filter :s3_region_name, as: :select
  filter :s3_bucket_name, as: :select
  filter :s3_file_path, as: :select

  config.sort_order = 'customers.slug_asc,slug_asc'

  index(download_links: false) do
    column(:name, sortable: :slug) { |workflow| auto_link(workflow) }
    column(:customer, sortable: 'customers.slug')
    column :slug
    boolean_column :shared
    column :s3_region_name
    column :s3_bucket_name
    column :s3_file_path
  end

  show do
    attributes_table do
      row :id

      row :customer

      row :name
      row :slug

      row :shared

      row :s3_region_name
      row :s3_bucket_name
      row :s3_file_path

      row :created_at
      row :updated_at
    end

    # FIXME - PARTIALIZE THE FOLLOWING AND THE CUSTOMER WORKFLOW PANEL

    included_workflows = workflow.included_workflows.order(:name).to_a
    unless included_workflows.empty?
      panel 'Associated Shared Workflows' do
        table_for(included_workflows) do
          column(:name) { |workflow| auto_link(workflow) }
          column(:slug)
          boolean_column(:shared)
          column :s3_region_name
          column :s3_bucket_name
          column :s3_file_path
        end
      end
    end

    including_workflows = resource.including_workflows.order(:name).to_a
    unless including_workflows.empty?
      panel 'Associated Customer Workflows' do
        table_for(including_workflows) do
          column(:name) { |workflow| auto_link(workflow) }
          column(:slug)
          boolean_column(:shared)
          column :s3_region_name
          column :s3_bucket_name
          column :s3_file_path
        end
      end
    end

    render partial: 'admin/workflow/s3_transform_panel',
           locals: { panel_name: 'Independent Transforms', transforms: resource.transforms.independent.to_a.sort_by(&:interpolated_name) }

    render partial: 'admin/workflow/s3_transform_panel',
           locals: { panel_name: 'Dependent, Data-Importing Transforms', transforms: resource.transforms.dependent.importing.to_a.sort_by(&:interpolated_name) }

    panel 'Dependent, non-Importing/Exporting Transforms' do

      text_node link_to("Create New Transform", new_transform_path(workflow_id: resource.id, source: :workflow))

      transforms = resource.transforms.dependent.non_file_related.to_a.sort_by(&:interpolated_name)
      unless transforms.empty?
        table_for(transforms) do
          column(:name, sortable: :name) { |transform| auto_link(transform) }
          column(:runner, sortable: :runner) { |transform| transform.runner }
          column(:actions) do |transform|
            text_node(link_to("Edit", edit_transform_path(transform, source: :workflow, workflow_id: transform.workflow_id)))
            text_node(' | ')
            text_node(link_to("Delete", transform_path(transform, source: :workflow), method: :delete, data: { confirm: 'Are you sure you want to nuke this Transform?' }))
          end
        end

        text_node "#{transforms.size} total"
      end
    end

    render partial: 'admin/workflow/s3_transform_panel',
           locals: { panel_name: 'Dependent, Data-Exporting Transforms', transforms: resource.transforms.dependent.exporting.to_a.sort_by(&:interpolated_name) }

    panel 'Data Quality Reports' do

      text_node link_to("Create New Data Quality Report", new_workflow_data_quality_report_path(workflow_id: resource.id))

      reports = resource.workflow_data_quality_reports.includes(:data_quality_report).to_a.sort_by(&:interpolated_name).to_a
      unless reports.empty?
        table_for(reports) do
          column(:workflow_data_quality_report) { |wdqr| auto_link(wdqr) }
          column(:interpolated_sql) { |wdqr| wdqr.interpolated_sql.truncate(120) }
          column('Immutable?') { |wdqr| yes_no(wdqr.data_quality_report.immutable?) }
          column(:action) do |wdqr|
            text_node(link_to("Edit", edit_workflow_data_quality_report_path(wdqr, source: :workflow, workflow_id: wdqr.workflow_id)))
            text_node(' | ')
            text_node(link_to("Delete", workflow_data_quality_report_path(wdqr, source: :workflow), method: :delete, data: { confirm: 'Are you sure you want to nuke this Workflow Data Quality Report?' }))
          end
        end

        text_node "#{reports.size} total"
      end
    end

    panel 'Runs' do

      text_node link_to("Run Now", run_workflow_path(workflow), method: :put)

      runs = resource.runs.includes(:creator).order(id: :desc).to_a
      unless runs.empty?
        table_for(runs) do
          column(:schema_name) { |run| auto_link(run) }
          column(:creator)
          column(:created_at)
          column(:human_status) { |run| human_status(run) }
          column(:action) { |run| link_to("Delete", run_path(run), method: :delete, data: { confirm: 'Are you sure you want to nuke this Run and all DB data associated with it?' }) }
        end
      end
    end

    panel 'Run Notifications' do

      text_node link_to("Add New Notifications", edit_workflow_path(workflow))

      notifications = resource.notifications.joins(:user).order('users.first_name, users.last_name').to_a
      unless notifications.empty?
        table_for(notifications) do
          column(:user) { |notification| auto_link(notification.user) }
          column(:action) { |notification| link_to("Delete", notification_path(notification), method: :delete, data: { confirm: 'Are you sure you want to nuke this Notification?' }) }
        end
      end
    end

    active_admin_comments

    render partial: 'admin/shared/history'
  end

  config.add_action_item :run_workflow, only: :show, if: proc { resource.transforms.count > 0 } do
    link_to("Run Now", run_workflow_path(workflow), method: :put)
  end

  member_action :run, method: :put do
    run = resource.run!(current_user)
    flash[:notice] = "Run generated."
    redirect_to run_path(run)
  end

  form do |f|
    # For debugging:
    semantic_errors *f.object.errors.keys

    inputs 'Details' do
      input :customer, as: :select, collection: customers_with_single_select, include_blank: !customer_id_from_param
      # FIXME - I'd like this to be as: :radio, but I don't know how to do the JS
      input :shared, as: :select, collection: [["Yes", true], ["No", false]], include_blank: false, input_html: { disabled: customer_id_from_param }
      input :name, as: :string
      input :slug, as: :string, hint: "Leave the slug blank if you want it to be auto-generated. And DON'T MAKE IT TOO LONG, or creating the Posgres schema will puke."

      input :s3_region_name, as: :string # This should be a drop-down
      input :s3_bucket_name, as: :string
      input :s3_file_path, as: :string

      # Same comment here as for TransformController's form: this doesn't work on #create b/c a Workflow is at either end of the join. Whereas, when the objects
      #  on either side of the join table are different, this works beautifully. IOW, Rails BUG
      if f.object.persisted? && Workflow.shared.exists?
        included_workflows_display_h = (f.object.shared? ? { style: 'display:none' } : {})
        input :included_workflows, as: :check_boxes, collection: Workflow.shared, wrapper_html: included_workflows_display_h
      end
    end

    inputs 'Run Notifications' do
      # The preselect doesn't work, for obvious reasons
      input :notified_users, as: :check_boxes #, collection: users_with_preselect
    end

    actions do
      action(:submit)
      path = (params[:source] == 'customer' ? customer_path(params[:customer_id]) : f.object.new_record? ? workflows_path : workflow_path(f.object))
      cancel_link(path)
    end
  end

  controller do

    def scoped_collection
      super.includes(:customer)
    end

    def destroy
      super do |success, failure|
        success.html { redirect_to(params[:source] == 'customer' ? customer_path(resource.customer) : workflows_path) }
      end
    end

  end

end
