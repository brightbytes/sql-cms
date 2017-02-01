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
      row :copied_from_workflow
      row :created_at
      row :updated_at
    end

    panel 'Transforms' do
      text_node link_to("Create New Transform", new_transform_path(workflow_id: resource.id, customer_id: resource.customer_id, source: :workflow))

      sort = params[:order].try(:gsub, '_asc', ' ASC').try(:gsub, '_desc', ' DESC') || :name
      table_for(resource.transforms.order(sort), sortable: true) do
        column(:name, sortable: :name) { |transform| auto_link(transform) }
        column(:runner, sortable: :runner) { |transform| transform.runner }
        column(:action) { |transform| link_to("Delete", transform_path(transform, source: :workflow), method: :delete) }
      end
    end

    panel 'Data Quality Reports' do
      text_node link_to("Create New Data Quality Report", new_data_quality_report_path(workflow_id: resource.id, customer_id: resource.customer_id, source: :workflow))

      sort = params[:order].try(:gsub, '_asc', ' ASC').try(:gsub, '_desc', ' DESC') || :name
      table_for(resource.data_quality_reports.order(sort), sortable: true) do
        column(:name, sortable: :name) { |dqr| auto_link(dqr) }
        column(:action) { |dqr| link_to("Delete", data_quality_report_path(dqr, source: :workflow), method: :delete) }
      end
    end

    panel 'Run Notifications' do
      table_for(resource.notifications.joins(:user).order('users.first_name, users.last_name')) do
        column(:user) { |notification| auto_link(notification.user) }
        column(:action) { |notification| link_to("Delete", notification_path(notification), method: :delete) }
      end
    end

    active_admin_comments

    render partial: 'admin/shared/history'
  end

  sidebar("Actions", only: :show) do
    ul do
      li link_to("Clone Workflow")
    end
  end

  form do |f|
    # For debugging:
    # semantic_errors *f.object.errors.keys
    inputs 'Details' do
      input :customer, as: :select, collection: customers_with_preselect
      input :name, as: :string
      input :slug, as: :string, hint: "Leave the slug blank if you want it to be auto-generated."
    end
    inputs 'Run Notifications' do
      input :notified_users, as: :check_boxes
    end
    actions do
      action(:submit)
      cancel_link(f.object.new_record? ? workflows_path : workflow_path(f.object))
    end
  end

  controller do

    def scoped_collection
      super.joins(:customer)
    end

  end

end
