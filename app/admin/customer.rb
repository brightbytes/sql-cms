ActiveAdmin.register Customer do

  scope "All", :with_deleted
  # For some reason, this doesn't use AR.all ...
  # scope "Undeleted Only", :all
  # ... hence this:
  scope "Undeleted Only", :sans_deleted, default: true
  scope "Deleted Only", :only_deleted

  actions :all

  config.add_action_item :undelete, only: :show, if: proc { resource.deleted? } do
    link_to "Undelete", undelete_customer_path(resource), method: :put
  end

  permit_params :name, :slug

  filter :name, as: :string

  config.sort_order = 'slug_asc'

  index download_links: false do
    column :customer do |customer|
      link_to customer.name, customer_path(customer)
    end
    column :slug
  end

  show do
    attributes_table do
      row :id
      row :name
      row :slug

      row :created_at
      row :updated_at
      row :deleted_at
    end

    active_admin_comments

    panel "History" do
      render partial: 'admin/shared/history', locals: { context: self, associated: customer }
    end
  end

  form do |f|
    inputs 'Details' do
      input :name, as: :string
      input :slug, as: :string, hint: "Leave the slug blank if you want it to be auto-generated."
    end
    f.actions
  end

  controller do

    def find_resource
      Customer.with_deleted.find_by(id: params[:id])
    end

    def action_methods
      result = super
      # Don't show the destroy button if the Customer is already destroyed, since a 2nd destroy will physically nuke the record
      result -= ['destroy'] if action_name == 'show' && resource.deleted?
      result
    end

  end

  member_action :undelete, method: :put do
    resource.recover
    flash[:notice] = "Customer Restored!"
    redirect_to customer_path(resource)
  end

end
