ActiveAdmin.register Customer do

  menu priority: 10

  actions :all

  permit_params :name, :slug

  config.sort_order = 'slug_asc'

  config.batch_actions = false

  config.paginate = false
  before_action :skip_sidebar!, only: :index

  index(download_links: false) do
    column(:name, sortable: :name) { |customer| auto_link(customer) }
    column('') { |customer| link_to("Edit", edit_customer_path(customer)) }
    column :slug
    column('') do |customer|
      if customer.used?
        text_node("Currently Used")
      else
        link_to("Delete", customer_path(customer), method: :delete, data: { confirm: "Are you sure you want to nuke this Customer?" })
      end
    end
  end

  show do
    attributes_table do
      row :id
      row :name
      row :slug

      row :created_at
      row :updated_at
    end

    workflow_configurations = resource.workflow_configurations.includes(:workflow).order('workflows.slug')
    unless workflow_configurations.empty?
      panel 'Workflow Configurations' do
        table_for(workflow_configurations) do
          column(:workflow_configuration) do |workflow_configuration|
            text_node(auto_link(workflow_configuration))
            text_node('&nbsp;&nbsp;&nbsp;|&nbsp;&nbsp;&nbsp;'.html_safe)
            text_node(link_to("Edit", edit_workflow_configuration_path(workflow_configuration, customer_id: resource.id, source: :customer)))
          end
          column(:workflow) { |workflow_configuration| auto_link(workflow_configuration.workflow) }
          # Makes for smaller profile
          # column :s3_region_name
          column :s3_bucket_name
          column :s3_file_path
          column('') do |workflow_configuration|
            if workflow_configuration.runs.count > 0
              text_node("Nuke Runs to Delete")
            else
              link_to(
                "Delete",
                workflow_configuration_path(workflow_configuration, source: :customer),
                method: :delete,
                data: { confirm: 'Are you really sure you want to nuke this Workflow Configuration?' }
              )
            end
          end
        end
      end
    end

    active_admin_comments

    render partial: 'admin/shared/history'
  end

  sidebar("Actions", only: :show) do
    ul do
      li link_to("Create New Workflow Configuration", new_workflow_configuration_path(customer_id: resource.id, source: :customer))
    end
  end

  form do |f|
    inputs 'Details' do
      input :name, as: :string
      input :slug, as: :string, hint: "Leave the slug blank if you want it to be auto-generated. And DON'T MAKE IT TOO LONG, or creating the Posgres schema will puke."
    end
    actions
  end

end
