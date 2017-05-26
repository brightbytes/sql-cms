ActiveAdmin.register Workflow do

  menu priority: 20

  actions :all

  permit_params :name, :slug, :default_copy_from_sql, :default_copy_from_s3_file_type, :default_copy_to_sql, :default_copy_to_s3_file_type, included_workflow_ids: []

  filter :name, as: :string
  filter :slug, as: :string

  config.sort_order = 'slug_asc'

  index(download_links: false) do
    column(:name, sortable: :slug) { |workflow| auto_link(workflow) }
    column :slug
    # These budge-out the display too much.
    # column :default_copy_from_sql
    # column :default_copy_from_s3_file_type
    # column :default_copy_to_sql
    # column :default_copy_to_s3_file_type
  end

  show do
    attributes_table do
      row :id

      row :name
      row :slug

      row :default_copy_from_sql
      row :default_copy_from_s3_file_type
      row :default_copy_to_sql
      row :default_copy_to_s3_file_type

      row :created_at
      row :updated_at
    end

    panel 'Workflow Configurations' do
      text_node link_to("Create New Workflow Configuration", new_workflow_configuration_path(workflow_id: resource.id, source: :workflow))

      table_for(resource.workflow_configurations.includes(:customer).order('customers.slug')) do
        column(:name) { |workflow_configuration| auto_link(workflow_configuration) }
        column(:customer) { |workflow_configuration| auto_link(workflow_configuration.customer) }
        column(:last_run_status) { |workflow_configuration| human_status(workflow_configuration.runs.order(:id).last) }
        # These are kinda clutter
        column :s3_region_name
        column :s3_bucket_name
        column :s3_file_path
        column(:action) do |workflow_configuration|
          text_node(
            link_to(
              "Edit",
              edit_workflow_configuration_path(workflow_configuration, workflow_id: resource.id, source: :workflow)
            )
          )
          text_node(' | ')
          link_to(
            "Delete",
            workflow_configuration_path(workflow_configuration, source: :workflow),
            method: :delete,
            data: { confirm: 'Are you really sure you want to nuke this Workflow Configuration?' }
          )
        end
      end
    end

    render partial: 'admin/workflow/workflow_panel',
           locals: { panel_name: 'Included Workflows', workflows: workflow.included_workflows.order(:name).to_a }

    render partial: 'admin/workflow/workflow_panel',
           locals: { panel_name: 'Including Workflows', workflows: resource.including_workflows.order(:name).to_a }

    render partial: 'admin/workflow/transform_panel',
           locals: { panel_name: 'Independent Transforms', transforms: resource.transforms.independent.to_a.sort_by(&:interpolated_name) }

    render partial: 'admin/workflow/transform_panel',
           locals: { panel_name: 'Dependent, Data-Importing Transforms', transforms: resource.transforms.dependent.importing.to_a.sort_by(&:interpolated_name) }

    render partial: 'admin/workflow/transform_panel',
           locals: { panel_name: 'Dependent, non-Importing/Exporting Transforms', transforms: resource.transforms.dependent.non_file_related.to_a.sort_by(&:interpolated_name) }

    render partial: 'admin/workflow/transform_panel',
           locals: { panel_name: 'Dependent, Data-Exporting Transforms', transforms: resource.transforms.dependent.exporting.to_a.sort_by(&:interpolated_name) }

    panel 'Data Quality Reports' do

      text_node link_to("Create New Data Quality Report", new_workflow_data_quality_report_path(workflow_id: resource.id))

      reports = resource.workflow_data_quality_reports.includes(:data_quality_report).to_a.sort_by(&:interpolated_name).to_a
      unless reports.empty?
        table_for(reports) do
          column(:workflow_data_quality_report) { |wdqr| auto_link(wdqr) }
          column(:interpolated_sql) { |wdqr| wdqr.interpolated_sql }
          column('Immutable?') { |wdqr| yes_no(wdqr.data_quality_report.immutable?) }
          column(:action) do |wdqr|
            text_node(link_to("Edit", edit_workflow_data_quality_report_path(wdqr, source: :workflow, workflow_id: wdqr.workflow_id)))
            text_node(' | ')
            text_node(link_to("Delete", workflow_data_quality_report_path(wdqr, source: :workflow), method: :delete, data: { confirm: 'Are you sure you want to nuke this Workflow Data Quality Report?' }))
          end
        end

        text_node "#{reports.size} total"
      end
    end

    active_admin_comments

    render partial: 'admin/shared/history'
  end

  form do |f|
    # For debugging:
    # semantic_errors *f.object.errors.keys

    inputs 'Details' do
      input :name, as: :string
      # FIXME - DON'T ALLOW IT TO BE TOO LONG!
      input :slug, as: :string, hint: "Leave the slug blank if you want it to be auto-generated. And DON'T MAKE IT TOO LONG, or creating the Posgres schema will puke."

      input :default_copy_from_sql, as: :string, hint: "This will be used as the SQL for the DefaultCopyFrom Runner"
      input :default_copy_from_s3_file_type, collection: Workflow::DEFAULT_S3_FILE_TYPES, include_blank: true, hint: "This will be used as the extention for the S3 file for the DefaultCopyFrom Runner"

      input :default_copy_to_sql, as: :string, hint: "This will be used as the SQL for the DefaultCopyToFrom Runner"
      input :default_copy_to_s3_file_type, collection: Workflow::DEFAULT_S3_FILE_TYPES, include_blank: true, hint: "This will be used as the extention for the S3 file for the DefaultCopyTo Runner"
    end

    inputs 'Dependencies' do
      input :included_workflows, as: :check_boxes, collection: f.object.available_included_workflows
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

  end

end
