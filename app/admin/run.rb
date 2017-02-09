ActiveAdmin.register Run do

  menu priority: 60

  actions :index, :show, :destroy

  filter :workflow, as: :select, collection: proc { Workflow.order(:slug).all }
  filter :creator, as: :select, collection: proc { User.order(:first_name, :last_name).all }
  filter :status, as: :string

  config.sort_order = 'workflows.slug_asc,id_asc'

  index(download_links: false) do
    column(:schema_name, sortable: 'schema_name') { |run| auto_link(run) }
    column(:workflow, sortable: 'workflows.slug')
    column(:customer, sortable: 'customers.slug')
    column(:creator, sortable: 'users.first_name,users.last_name')
    column(:succeeded_so_far?) { |run| yes_no(run.succeeded_so_far?, yes_color: :green, no_color: :red) }
    column(:failed?) { |run| yes_no(run.failed?, yes_color: :red, no_color: :green) }
    column(:running_or_crashed?) { |run| yes_no(run.running_or_crashed?) }
  end

  show do
    attributes_table do
      row :id
      row :schema_name
      row :workflow
      row :customer
      row(:succeeded_so_far?) { |run| yes_no(run.succeeded_so_far?, yes_color: :green, no_color: :red) }
      row(:failed?) { |run| yes_no(run.failed?, yes_color: :red, no_color: :green) }
      row(:running_or_crashed?) { |run| yes_no(run.running_or_crashed?) }
      row :status
      row :creator
      row :created_at
      row :updated_at
    end

    active_admin_comments

    panel 'Run Step Logs' do
      sort = params[:order].try(:gsub, '_asc', ' ASC').try(:gsub, '_desc', ' DESC') || :name
      table_for(resource.run_step_logs.order('id'), sortable: true) do
        column(:step_type, sortable: :step_type) { |log| auto_link(log) }
        column(:step_plan) { |plan| code(pretty_print_as_json(plan)) }
        boolean_column(:running)
        boolean_column(:successful)
      end
    end

    attributes_table do
      row(:execution_plan) { code(pretty_print_as_json(resource.execution_plan)) }
    end

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
