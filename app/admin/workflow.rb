ActiveAdmin.register Workflow do

  menu priority: 20

  actions :all

  permit_params :name, :customer_id, :slug, notified_user_ids: []

  filter :name, as: :string
  filter :customer, as: :select, collection: proc { Customer.order(:slug).all }

  config.sort_order = 'customers.slug_asc,slug_asc'

  index(download_links: false) do
    column(:name, sortable: :slug) { |workflow| auto_link(workflow) }
    column(:customer, sortable: 'customers.slug')
    # column :slug
  end

  show do
    attributes_table do
      row :id
      row :customer
      row :name
      row :slug
      row :created_at
      row :updated_at
    end

    para link_to("Create New Transform", new_transform_path(workflow_id: resource.id, customer_id: resource.customer_id, source: :workflow))

    # FIXME - GET RID OF COPY/PASTE

    panel 'Independent Transforms' do
      table_for(resource.transforms.independent.order(:name)) do
        column(:name, sortable: :name) { |transform| auto_link(transform) }
        column(:runner, sortable: :runner) { |transform| transform.runner }
        column(:action) { |transform| link_to("Delete", transform_path(transform, source: :workflow), method: :delete, data: { confirm: 'Are you sure you want to nuke this Transform?' }) }
      end
    end

    panel 'Data-Importing Transforms' do
      table_for(resource.transforms.importing.order(:name)) do
        column(:name, sortable: :name) { |transform| auto_link(transform) }
        column(:runner, sortable: :runner) { |transform| transform.runner }
        column(:s3_region_name)
        column(:s3_bucket_name)
        column(:s3_file_path)
        column(:s3_file_name)
        column(:s3_file_exists?) { |transform| transform.exporting? ? 'n/a' : yes_no(transform.s3_file_exists?, yes_color: :green, no_color: :red) }
        column(:action) { |transform| link_to("Delete", transform_path(transform, source: :workflow), method: :delete, data: { confirm: 'Are you sure you want to nuke this Transform?' }) }
      end
    end

    panel 'Dependent, non-Importing/Exporting Transforms' do
      table_for(resource.transforms.dependent_non_file_related.order(:name)) do
        column(:name, sortable: :name) { |transform| auto_link(transform) }
        column(:runner, sortable: :runner) { |transform| transform.runner }
        column(:action) { |transform| link_to("Delete", transform_path(transform, source: :workflow), method: :delete, data: { confirm: 'Are you sure you want to nuke this Transform?' }) }
      end
    end

    panel 'Data-Exporting Transforms' do
      table_for(resource.transforms.exporting.order(:name)) do
        column(:name, sortable: :name) { |transform| auto_link(transform) }
        column(:runner, sortable: :runner) { |transform| transform.runner }
        column(:s3_region_name)
        column(:s3_bucket_name)
        column(:s3_file_path)
        column(:s3_file_name)
        column(:action) { |transform| link_to("Delete", transform_path(transform, source: :workflow), method: :delete, data: { confirm: 'Are you sure you want to nuke this Transform?' }) }
      end
    end

    panel 'Data Quality Reports' do
      text_node link_to("Create New Data Quality Report", new_data_quality_report_path(workflow_id: resource.id, customer_id: resource.customer_id, source: :workflow))

      table_for(resource.data_quality_reports.order(:name)) do
        column(:name) { |dqr| auto_link(dqr) }
        column(:action) { |dqr| link_to("Delete", data_quality_report_path(dqr, source: :workflow), method: :delete, data: { confirm: 'Are you sure you want to nuke this Data Quality Report?' }) }
      end
    end

    panel 'Runs' do
      table_for(resource.runs.includes(:creator).order(id: :desc)) do
        column(:schema_name) { |run| auto_link(run) }
        column(:creator)
        column(:human_status) { |run| human_status(run) }
      end
    end

    panel 'Run Notifications' do
      table_for(resource.notifications.joins(:user).order('users.first_name, users.last_name')) do
        column(:user) { |notification| auto_link(notification.user) }
        column(:action) { |notification| link_to("Delete", notification_path(notification), method: :delete, data: { confirm: 'Are you sure you want to nuke this Notification?' }) }
      end
    end

    active_admin_comments

    render partial: 'admin/shared/history'
  end

  config.add_action_item :run_workflow, only: :show, if: proc { resource.transforms.count > 0 } do
    link_to("Run!", run_workflow_path(workflow), method: :put)
  end

  member_action :run, method: :put do
    run = resource.run!(current_user)
    flash[:notice] = "Run generated."
    redirect_to run_path(run)
  end

  form do |f|
    # For debugging:
    # semantic_errors *f.object.errors.keys
    inputs 'Details' do
      editing = action_name.in?(%w(edit update))
      input :customer, as: :select, collection: customers_with_single_select, include_blank: params[:customer_id].blank?, input_html: { disabled: editing }
      input :name, as: :string
      input :slug, as: :string, hint: "Leave the slug blank if you want it to be auto-generated."
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
      super.joins(:customer)
    end

    def destroy
      super do |success, failure|
        success.html { redirect_to(params[:source] == 'customer' ? customer_path(resource.customer) : workflows_path) }
      end
    end

  end

end
