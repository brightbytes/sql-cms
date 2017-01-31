ActiveAdmin.register Workflow do

  menu priority: 20

  actions :all

  permit_params :name, :customer_id, :slug

  filter :name, as: :string
  filter :customer, as: :select, collection: proc { Customer.order(:slug).all }

  config.sort_order = 'customers.slug_asc,slug_asc'

  index(download_links: false) do
    # id_column
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

    panel 'Notifications' do
      text_node link_to("Create New Notification", new_notification_path(workflow_id: resource.id)) if any_notifiable_users?(workflow)

      table_for(resource.notifications.joins(:user).order('users.first_name, users.last_name')) do
        column(:user) { |notification| auto_link(notification.user) }
        column(:action) { |notification| link_to("Delete", notification_path(notification), method: :delete) }
      end
    end

    active_admin_comments

    render partial: 'admin/shared/history'
  end

  form do |f|
    # For debugging:
    # semantic_errors *f.object.errors.keys
    inputs 'Details' do
      input :customer, as: :select, collection: customers_with_preselect
      input :name, as: :string
      input :slug, as: :string, hint: "Leave the slug blank if you want it to be auto-generated."
    end
    actions
  end

  controller do

    def scoped_collection
      super.joins(:customer)
    end

  end

end
