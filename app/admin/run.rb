ActiveAdmin.register Run do

  menu priority: 60

  actions :index, :show, :destroy

  filter :workflow, as: :select, collection: proc { Workflow.order(:slug).all }
  filter :creator, as: :select, collection: proc { User.order(:first_name, :last_name).all }
  filter :status, as: :string

  config.sort_order = 'workflows.slug_asc,id_asc'

  index(download_links: false) do
    column(:workflow, sortable: 'workflows.slug')
    column(:customer, sortable: 'customers.slug')
    column(:creator, sortable: 'users.first_name,users.last_name')
    column(:schema_name, sortable: 'schema_prefix,id')
    column(:status)
  end

  show do
    attributes_table do
      row :id
      row :workflow
      row :creator

      row(:execution_plan) { code(pretty_print_as_json(resource.execution_plan)) }
      row(:status)

      row :created_at
      row :updated_at
    end

    active_admin_comments

    # Add partial for run_step_logs here

    render partial: 'admin/shared/history'
  end


  controller do

    def scoped_collection
      super.joins(:creator, { workflow: :customer })
    end

    def destroy
      super do |success, failure|
        success.html do
          redirect_to(workflow_path(resource.workflow))
        end
      end
    end

  end

end
