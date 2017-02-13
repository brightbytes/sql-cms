ActiveAdmin.register Customer do

  menu priority: 10

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

  index(download_links: false) do
    id_column
    column(:name, sortable: :slug) { |customer| auto_link(customer) }
    # column :slug
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

    panel 'Workflows' do
      text_node link_to("Create New Workflow", new_workflow_path(customer_id: customer.id, source: :customer))

      sort = params[:order].try(:gsub, '_asc', ' ASC').try(:gsub, '_desc', ' DESC') || :name
      table_for(resource.workflows.order(sort), sortable: true) do
        column(:name, sortable: :name) { |workflow| auto_link(workflow) }
        column(:action) { |workflow| link_to("Delete", workflow_path(workflow, source: :customer), method: :delete, data: { confirm: 'Are you really, really, really sure you want to nuke this Workflow?  Really???' }) }
      end
    end

    panel 'Data Files' do
      text_node link_to("Create New Data File", new_data_file_path(customer_id: customer.id, source: :customer))

      sort = params[:order].try(:gsub, '_asc', ' ASC').try(:gsub, '_desc', ' DESC') || :name
      table_for(resource.data_files.order(sort), sortable: true) do
        column(:name, sortable: :name) { |data_file| auto_link(data_file) }
        column(:file_type, sortable: :file_type)
        column(:s3_region_name, sortable: :s3_region_name)
        column(:s3_bucket_name, sortable: :s3_bucket_name)
        column(:s3_file_path, sortable: :s3_file_path)
        column(:s3_file_name, sortable: :s3_file_name)
        column(:s3_file_exists?) { |data_file| data_file.export? ? 'n/a' : yes_no(data_file.s3_file_exists?, yes_color: :green, no_color: :red) }
        column(:action) { |data_file| link_to("Delete", data_file_path(data_file, source: :customer), method: :delete, data: { confirm: 'Are you sure you want to nuke this Data File?' }) }
      end
    end

    active_admin_comments

    render partial: 'admin/shared/history'
  end

  form do |f|
    inputs 'Details' do
      input :name, as: :string
      input :slug, as: :string, hint: "Leave the slug blank if you want it to be auto-generated."
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
    resource.recover
    flash[:notice] = "Customer Restored!"
    redirect_to customer_path(resource)
  end

end
