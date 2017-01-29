ActiveAdmin.register Workflow do

  menu priority: 20

  actions :all

  permit_params :name, :customer_id

  filter :name, as: :string
  filter :customer, as: :select, collection: proc { Customer.order(:slug).all }

  config.sort_order = 'customer.name_asc,name_asc'

  index(download_links: false) do
    id_column
    column :name
    column :customer
  end

  show do
    attributes_table do
      row :id
      row :customer
      row :name
      row :copied_from_workflow
      row :created_at
      row :updated_at
    end

    panel 'User Notifications' do
      ul do
        li link_to("Create New Notification", )
      end
      sort = params[:order].try(:gsub, '_asc', ' ASC').try(:gsub, '_desc', ' DESC') || :name
      table_for(resource.notified_users.order(sort), sortable: true) do
        column(:user, sortable: :name) { |user| auto_link(user) }
      end
    end

    active_admin_comments

    render partial: 'admin/shared/history'
  end

  form do |f|
    # For debugging:
    semantic_errors *f.object.errors.keys
    inputs 'Details' do
      input :customer, as: :select, collection: Customer.order(:slug).all
      input :name, as: :string
    end
    actions
  end



end
