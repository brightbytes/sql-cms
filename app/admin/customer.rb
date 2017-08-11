ActiveAdmin.register Customer do

  menu priority: 10

  scope "All", :with_deleted
  # For some reason, this doesn't use AR.all ...
  # scope "Undeleted Only", :all
  # ... hence this:
  scope "Undeleted Only", :sans_deleted, default: true
  scope "Deleted Only", :only_deleted

  actions :all

  permit_params :name, :slug

  config.add_action_item :undelete, only: :show, if: proc { resource.deleted? } do
    link_to "Undelete", undelete_customer_path(resource), method: :put
  end

  config.sort_order = 'slug_asc'

  config.batch_actions = false

  config.paginate = false
  before_action :skip_sidebar!, only: :index

  index(download_links: false) do
    id_column
    column(:name, sortable: :slug) { |customer| auto_link(customer) }
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

    panel 'Workflow Configurations' do
      text_node link_to("Create New Workflow Configuration", new_workflow_configuration_path(customer_id: resource.id, source: :customer))

      table_for(resource.workflow_configurations.includes(:workflow).order('workflows.slug')) do
        column(:workflow_configuration) { |workflow_configuration| auto_link(workflow_configuration) }
        column(:workflow) { |workflow_configuration| auto_link(workflow_configuration.workflow) }
        column :s3_region_name
        column :s3_bucket_name
        column :s3_file_path
        column(:action) do |workflow_configuration|
          text_node(
            link_to(
              "Edit",
              edit_workflow_configuration_path(workflow_configuration, customer_id: resource.id, source: :customer)
            )
          )
          text_node(' | ')
          link_to(
            "Delete",
            workflow_configuration_path(workflow_configuration, source: :customer),
            method: :delete,
            data: { confirm: 'Are you really sure you want to nuke this Workflow Configuration?' }
          )
        end
      end
    end

    active_admin_comments

    render partial: 'admin/shared/history'
  end

  form do |f|
    inputs 'Details' do
      input :name, as: :string
      input :slug, as: :string, hint: "Leave the slug blank if you want it to be auto-generated. And DON'T MAKE IT TOO LONG, or creating the Posgres schema will puke."
    end
    actions
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
    resource.restore
    flash[:notice] = "Customer Restored!"
    redirect_to customer_path(resource)
  end

end
