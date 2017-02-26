ActiveAdmin.register Transform do

  menu priority: 30

  actions :all

  permit_params :name, :runner, :workflow_id, :params_yaml, :sql, :specify_s3_file_by, :supplied_s3_url, :s3_region_name, :s3_bucket_name, :s3_file_path, :s3_file_name, prerequisite_transform_ids: []

  filter :name, as: :string
  filter :runner, as: :select, collection: RunnerFactory::RUNNERS
  filter :workflow, as: :select, collection: proc { Workflow.order(:slug).all }
  filter :sql, as: :string
  filter :s3_region_name, as: :select
  filter :s3_bucket_name, as: :select

  config.sort_order = 'workflows.slug_asc,name_asc'

  index(download_links: false) do
    column(:name) { |transform| auto_link(transform) }
    column(:workflow, sortable: 'workflows.slug')
    column(:customer, sortable: 'customers.slug')
    column(:runner)
  end

  show do
    attributes_table do
      row :id
      row :name
      row :workflow
      row :customer

      row :runner
      row(:params) { code(pretty_print_as_json(resource.params)) }
      if resource.runner == 'RailsMigration'
        ruby_format_row(:sql)
      else
        simple_format_row(:sql)
      end
      simple_format_row(:interpolated_sql) if resource.params.present?

      if transform.importing? || transform.exporting?
        error_msg = "<br /><span style='color: red'>Either the s3_region_name or the s3_bucket_name is not valid because S3 pukes on it!</span>".html_safe
        row(:s3_region_name) do
          text_node(transform.s3_region_name)
          text_node(error_msg) if transform.importing? && !transform.s3_import_file.s3_object_valid?
        end
        row(:s3_bucket_name)do
          text_node(transform.s3_bucket_name)
          text_node(error_msg) if transform.importing? && !transform.s3_import_file.s3_object_valid?
        end
        row :s3_file_path
        row :s3_file_name
        row(:s3_file_exists?) { yes_no(resource.s3_import_file.s3_file_exists?, yes_color: :green, no_color: :red) } if transform.importing?
      end

      row :created_at
      row :updated_at
    end

    panel 'Transform Validations' do
      text_node link_to("Add New Transform Validation", new_transform_validation_path(transform_id: resource.id))

      sort = params[:order].try(:gsub, '_asc', ' ASC').try(:gsub, '_desc', ' DESC') || :name
      table_for(resource.transform_validations.includes(:validation).order('validations.name'), sortable: true) do
        column(:transform_validation, sortable: :name) { |tv| auto_link(tv) }
        # Doesn't work, FML
        # column(:params) { |tv| code(tv.params) }
        column(:params) { |tv| tv.params }
        column(:validation_immutable) { |tv| yes_no(tv.validation.immutable?) }
        column(:action) { |tv| link_to("Delete", transform_validation_path(tv), method: :delete, data: { confirm: 'Are you sure you want to nuke this Transform Validation?' }) }
      end
    end

    panel 'Prerequisite Transform Dependencies' do
      sort = params[:order].try(:gsub, '_asc', ' ASC').try(:gsub, '_desc', ' DESC') || :name
      table_for(resource.prerequisite_dependencies.includes(:prerequisite_transform).order('transforms.name'), sortable: true) do
        column(:name, sortable: :name) { |pd| auto_link(pd.prerequisite_transform) }
        column(:runner, sortable: :runner) { |pd| pd.prerequisite_transform.runner }
        column(:action) { |pd| link_to("Delete", transform_dependency_path(pd, source: :postrequisite_transform), method: :delete, data: { confirm: 'Are you sure you want to nuke this Transform Dependency?' }) }
      end
    end

    panel 'Postrequisite Transforms Dependencies' do
      sort = params[:order].try(:gsub, '_asc', ' ASC').try(:gsub, '_desc', ' DESC') || :name
      table_for(resource.postrequisite_dependencies.includes(:postrequisite_transform).order('transforms.name'), sortable: true) do
        column(:name, sortable: :name) { |pd| auto_link(pd.postrequisite_transform) }
        column(:runner, sortable: :runner) { |pd| pd.postrequisite_transform.runner }
        column(:action) { |pd| link_to("Delete", transform_dependency_path(pd, source: :prerequisite_transform), method: :delete, data: { confirm: 'Are you sure you want to nuke this Transform Dependency?' }) }
      end
    end

    active_admin_comments

    render partial: 'admin/shared/history'
  end

  sidebar("Actions", only: :show) do
    ul do
      li link_to("Upload File to S3") if resource.importing? && !resource.s3_import_file.s3_file_exists?
    end
  end

  form do |f|
    inputs 'Details' do
      input :customer_id, as: :hidden, input_html: { value: transform_customer_id_param_val }
      input :workflow_id, as: :hidden, input_html: { value: workflow_id_param_val }
      input :workflow, as: :select, collection: workflows_with_single_select, include_blank: params[:workflow_id].blank?, input_html: { disabled: f.object.persisted? }

      input :name, as: :string
      input :runner, as: :select, collection: RunnerFactory::RUNNERS, input_html: { disabled: f.object.persisted? }

      # FIXME - IT'S REALLY TOO BAD THIS LINE CAN'T BE MADE TO WORK LIKE THIS: https://lorefnon.me/2015/03/02/dealing-with-json-fields-in-active-admin.html
      #         (I TRIED, AND FAILED: DOESN'T WORK IN THE LATEST VERSION OF AA)
      input :params_yaml, as: :text

      input :sql, as: :text

      if f.object.persisted?

        input :s3_region_name, as: :string # This should be a drop-down
        input :s3_bucket_name, as: :string
        input :s3_file_path, as: :string
        input :s3_file_name, as: :string

      else

        show_s3_url = f.object.supplied_s3_url.present?
        show_s3_file = !show_s3_url && f.object.s3_file_name.present?
        show_s3_selector = ((show_s3_url || show_s3_file) ? {} : { style: 'display:none' })
        input :specify_s3_file_by, as: :select, collection: [['HTTPS URL for existing S3 file', :url], ['S3 file location for future upload', :s3_fields]], wrapper_html: show_s3_selector, required: true, include_blank: false

        # For import files ...
        url_display_h = (show_s3_url ? {} : { style: 'display:none' })
        input :supplied_s3_url, label: "S3 File URL", required: true, wrapper_html: url_display_h, hint: "Copy/paste the https:// URL from S3"

        # For export files ...
        file_display_h = (show_s3_file ? {} : { style: 'display:none' })
        input :s3_region_name, as: :string, wrapper_html: file_display_h # should be a drop-down
        input :s3_bucket_name, as: :string, wrapper_html: file_display_h
        input :s3_file_path, as: :string, wrapper_html: file_display_h

        input :s3_file_name, as: :string, wrapper_html: file_display_h, hint: "This file doesn't need to exist yet; you may upload it on the next page."

      end

    end

    # We don't know the :workflow if we're creating, so we can't populate these
    # (Yes, we do know params[:workflow_id] if we get here from the Workflow, BUT, the .save goes sideways because Rails tries to save the assn before the main obj,
    #  and it's just not worth my time to debug.)
    if f.object.persisted?
      inputs 'Dependencies' do
        input :prerequisite_transforms, as: :check_boxes, collection: f.object.available_prerequisite_transforms
      end
    end

    actions do
      action(:submit)
      path = (params[:source] == 'workflow' ? workflow_path(params[:workflow_id]) : f.object.new_record? ? transforms_path : transform_path(f.object))
      cancel_link(path)
    end
  end

  controller do

    def scoped_collection
      super.joins(workflow: :customer)
    end

    def destroy
      super do |success, failure|
        success.html do
          redirect_to(params[:source] == 'workflow' ? workflow_path(resource.workflow) : transforms_path)
        end
      end
    end

  end

end
