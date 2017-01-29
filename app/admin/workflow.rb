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
      text_node link_to("Create New Notification", )

      sort = params[:order].try(:gsub, '_asc', ' ASC').try(:gsub, '_desc', ' DESC') || :first_name
      table_for(resource.notified_users.order(sort), sortable: true) do
        column(:user, sortable: :first_name) { |user| auto_link(user) }
      end
    end

    active_admin_comments

    render partial: 'admin/shared/history'
  end

  form do |f|
    # For debugging:
    # semantic_errors *f.object.errors.keys
    inputs 'Details' do
      input :customer, as: :select, collection: proc { Customer.order(:slug).map { |c| [c.name, c.id, selected: (c.id == params[:customer_id].to_i)] } }.call
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
