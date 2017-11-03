ActiveAdmin.register Workflow do

  menu priority: 20

  actions :all

  permit_params :name, :slug, :params_yaml, included_workflow_ids: []

  filter :name, as: :string
  filter :slug, as: :string

  config.sort_order = 'slug_asc'

  index(download_links: false) do
    column(:name, sortable: :slug) { |workflow| auto_link(workflow) }
    column('') { |workflow| link_to("Edit", edit_workflow_path(workflow)) }
    column :slug
    column('') do |workflow|
      workflow_config_ids = workflow.workflow_configurations.pluck(:id)
      if Run.where(workflow_configuration_id: workflow_config_ids).exists?
        text_node("Nuke All Runs to Delete")
      else
        link_to(
          "Delete",
          workflow_path(workflow),
          method: :delete,
          data: { confirm: 'Are you really sure you want to nuke this Workflow?' }
        )
      end
    end
  end

  show do
    attributes_table do
      row :id

      row :name
      row :slug

      simple_format_row(:params_yaml)

      row :created_at
      row :updated_at
    end

    render partial: 'admin/workflow/run_panel',
           locals: { panel_name: 'Runs', runs: resource.runs.order(id: :desc).to_a }

    configs = resource.workflow_configurations.includes(:customer).order('customers.slug')
    unless configs.empty?
      panel 'Workflow Configurations' do
        table_for(configs) do
          column(:name) do |workflow_configuration|
            text_node(auto_link(workflow_configuration))
            text_node('&nbsp;&nbsp;&nbsp;|&nbsp;&nbsp;&nbsp;'.html_safe)
            text_node(link_to("Edit", edit_workflow_configuration_path(workflow_configuration, workflow_id: resource.id, source: :workflow)))
            text_node('&nbsp;&nbsp;&nbsp;|&nbsp;&nbsp;&nbsp;'.html_safe)
            text_node(link_to("Run Now", run_workflow_configuration_path(workflow_configuration), method: :put))
          end
          column(:customer) { |workflow_configuration| auto_link(workflow_configuration.customer) }
          column(:last_run_status) { |workflow_configuration| human_status(workflow_configuration.runs.order(:id).last) }
          # These are kinda clutter; removing now that actions have been moved back to the sidebar
          # column :s3_region_name
          # column :s3_bucket_name
          # column :s3_file_path
          column('') do |workflow_configuration|
            if workflow_configuration.runs.count > 0
              text_node("Nuke All Runs to Delete")
            else
              link_to(
                "Delete",
                workflow_configuration_path(workflow_configuration, source: :workflow),
                method: :delete,
                data: { confirm: 'Are you really sure you want to nuke this Workflow Configuration?' }
              )
            end
          end
        end
      end
    end

    render partial: 'admin/workflow/workflow_panel',
           locals: { panel_name: 'Included Workflows', workflows: workflow.included_workflows.order(:name).to_a }

    render partial: 'admin/workflow/workflow_panel',
           locals: { panel_name: 'Including Workflows', workflows: resource.including_workflows.order(:name).to_a }

    step_index = 0
    step_index_subtractor = 0
    plan = ExecutionPlan.create(resource.workflow_configurations.first || WorkflowConfiguration.new(workflow: resource))
    while transform_ids = plan.transform_group_transform_ids(step_index) do
      transforms = resource.transforms.where(id: transform_ids).to_a.sort_by(&:interpolated_name)
      if transforms.present? # They won't be present for included workflows
        render partial: 'admin/workflow/transform_panel',
               locals: { panel_name: "Transform Group #{step_index - step_index_subtractor}", transforms: transforms }
      else
        step_index_subtractor += 1
      end
      step_index += 1
    end

    reports = resource.workflow_data_quality_reports.includes(:data_quality_report).to_a.sort_by(&:interpolated_name).to_a
    unless reports.empty?
      panel 'Data Quality Reports' do
        table_for(reports) do
          column(:workflow_data_quality_report) { |wdqr| auto_link(wdqr) }
          column('') { |wdqr| link_to("Edit Association", edit_workflow_data_quality_report_path(wdqr, source: :workflow, workflow_id: wdqr.workflow_id)) }
          column(:interpolated_sql) { |wdqr| wdqr.interpolated_sql }
          column('') do |wdqr|
            link_to("Delete Association", workflow_data_quality_report_path(wdqr, source: :workflow), method: :delete, data: { confirm: 'Are you sure you want to nuke this association to a Data Quality Report?' })
          end
        end

        text_node "#{reports.size} total"
      end
    end

    active_admin_comments

    render partial: 'admin/shared/history'
  end

  sidebar("Actions", only: :show) do
    ul do
      li link_to("Create Transform", new_transform_path(workflow_id: resource.id, source: :workflow))
      li link_to("Create Workflow Data Quality Report", new_workflow_data_quality_report_path(workflow_id: resource.id))
      li link_to("Create Workflow Configuration", new_workflow_configuration_path(workflow_id: resource.id, source: :workflow))
      configs = resource.workflow_configurations.to_a
      li link_to("Run Now - for Default Configuration", run_workflow_configuration_path(configs.first), method: :put) if configs.size == 1
    end
  end

  form do |f|
    # For debugging:
    # semantic_errors *f.object.errors.keys

    inputs 'Details' do
      input :name, as: :string
      # FIXME - DON'T ALLOW IT TO BE TOO LONG VIA A MODEL VALIDATION!
      input :slug, as: :string, hint: "Leave the slug blank if you want it to be auto-generated. And DON'T MAKE IT TOO LONG, or creating the Posgres schema will puke."

      input :params_yaml, as: :text, input_html: { rows: 10 }
    end

    if Workflow.count > 1
      inputs 'Dependencies' do
        input :included_workflows, as: :check_boxes, collection: f.object.available_included_workflows
      end
    end

    actions
  end

  controller do

    def create
      # This hackaround is because Rails tries to save the join obj before the main obj has been saved (I think)
      # HOWEVER, the "has_many :through accepts_nested_attributes_for" thing works GREAT on Workflow#create for Workflow#notified_users ...
      #          and I can't suss what's different here. (The associations and inverse_ofs are identically structured.)
      #          My only guess is that the issue is b/c a Workflow is at either end of the join.
      ids = params[:workflow].delete(:included_workflow_ids)&.reject(&:blank?)
      super do |success, failure|
        success.html do
          resource.included_workflow_ids = ids
          resource.save!
          redirect_to workflow_path(resource)
        end
      end
    end

    def destroy
      # We don't pluck b/c resource.workflow_configurations is used below in the happy path
      workflow_config_ids = resource.workflow_configurations.map(&:id)
      if Run.where(workflow_configuration_id: workflow_config_ids).exists?
        flash[:error] = "You must manually delete all Runs associated with every associated WorkflowConfiguration before deleting this Workflow."
        # This no-workie:
        # return redirect_to(:back)
        return redirect_to(workflow_path(resource))
      end
      resource.workflow_configurations.each(&:destroy)
      super
    end


  end

end
