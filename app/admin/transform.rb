ActiveAdmin.register Transform do

  menu priority: 30

  actions :all

  permit_params :name, :runner, :workflow_id, :params_yaml, :sql, :s3_file_name, :enabled, :source, prerequisite_transform_ids: []

  filter :workflow, as: :select, collection: proc { Workflow.order(:slug).all }
  filter :name, as: :string
  filter :runner, as: :select, collection: RunnerFactory::RUNNERS_FOR_SELECT
  filter :sql, as: :string
  filter :s3_file_name, as: :string

  config.sort_order = 'name_asc'

  index(download_links: false) do
    column(:name) do |transform|
      text_node(auto_link(transform))
      text_node('&nbsp;&nbsp;&nbsp;|&nbsp;&nbsp;&nbsp;'.html_safe)
      text_node(link_to("Edit", edit_transform_path(transform)))
    end
    column(:workflow, sortable: 'workflows.slug')
    column(:runner)
    boolean_column(:enabled)
    column('') do |transform|
      link_to(
        "Delete",
        transform_path(transform),
        method: :delete,
        data: { confirm: 'Are you really sure you want to nuke this Transform and all its Dependencies and TransformValidations?' }
      )
    end
  end

  show do
    attributes_table do
      row :id
      row :name
      row :interpolated_name if resource.params.present? && resource.name != resource.interpolated_name
      row :workflow
      boolean_row :enabled

      row :runner
      simple_format_row(:params_yaml)
      simple_format_row(:workflow_params_yaml)
      simple_format_row(:sql)
      simple_format_row(:interpolated_sql) if resource.sql != resource.interpolated_sql

      if resource.importing? || resource.exporting?
        row :s3_file_name
        row :interpolated_s3_file_name if resource.params.present? && resource.s3_file_name != resource.interpolated_s3_file_name
      end

      row :created_at
      row :updated_at
    end

    if transform.importing? || transform.exporting?
      workflow_configurations = resource.workflow_configurations.includes(:customer).order('customers.slug, workflows.slug').to_a
      unless workflow_configurations.empty?
        error_msg = "<br /><span style='color: red'>Either the s3_region_name or the s3_bucket_name is not valid because S3 pukes on it!</span>".html_safe
        panel 'Workflow Configuration S3 Files' do
          table_for(workflow_configurations) do
            column(:workflow_configuration) { |wc| auto_link(wc) }
            # This bloats the display too much
            # column(:s3_region_name) do |wc|
            #   text_node(wc.s3_region_name)
            #   text_node(error_msg) if transform.importing? && !transform.s3_import_file(wc).s3_object_valid?
            # end
            column(:s3_bucket_name) do |wc|
              text_node(wc.s3_bucket_name)
              text_node(error_msg) if transform.importing? && !transform.s3_import_file(wc).s3_object_valid?
            end
            column :s3_file_path
            column :s3_file_name { |wc| transform.interpolated_s3_file_name }
            if transform.importing?
              column :s3_file_exists? { |wc| yes_no(transform.s3_import_file(wc).s3_file_exists?, yes_color: :green, no_color: :red) }
              # FIXME - IMPLEMENT!!!
              # unless transform.s3_import_file(wc).s3_file_exists?
              #   column :action { |wc| li link_to("Upload File to S3") }
              # end
            end
          end
        end
      end
    end

    transform_validations = resource.transform_validations.includes(:validation).order('validations.name').to_a
    unless transform_validations.empty?
      panel 'Transform Validations' do
        table_for(transform_validations) do
          column(:transform_validation) { |tv| auto_link(tv) }
          column('') do |tv|
            link_to("Edit", edit_transform_validation_path(tv, source: :transform, transform_id: tv.transform_id))
          end
          column(:interpolated_sql) { |tv| tv.interpolated_sql }
          column('') do |tv|
            link_to("Delete", transform_validation_path(tv), method: :delete, data: { confirm: 'Are you sure you want to nuke this Transform Validation?' })
          end
        end
      end
    end

    prereqs = resource.prerequisite_dependencies.includes(:prerequisite_transform).to_a.sort_by { |td| td.prerequisite_transform.interpolated_name }
    unless prereqs.empty?
      panel 'Prerequisite Transform Dependencies' do
        table_for(prereqs) do
          column(:name) { |pd| auto_link(pd.prerequisite_transform) }
          column('') do |pd|
            link_to("Edit Transform", edit_transform_path(pd.prerequisite_transform, source: :postrequisite_transform))
          end
          column(:runner) { |pd| pd.prerequisite_transform.runner }
          column(:transform_enabled) { |pd| yes_no(pd.prerequisite_transform.enabled?) }
          column('') do |pd|
            link_to("Delete Dependency", transform_dependency_path(pd, source: :postrequisite_transform), method: :delete, data: { confirm: 'Are you sure you want to nuke this Transform Dependency?' })
          end
        end
      end
    end

    postreqs = resource.postrequisite_dependencies.includes(:postrequisite_transform).to_a.sort_by { |td| td.postrequisite_transform.interpolated_name }
    unless postreqs.empty?
      panel 'Postrequisite Transforms Dependencies' do
        table_for(postreqs) do
          column(:name) { |pd| auto_link(pd.postrequisite_transform) }
          column('') do |pd|
            link_to("Edit Transform", edit_transform_path(pd.postrequisite_transform, source: :prerequisite_transform))
          end
          column(:runner) { |pd| pd.postrequisite_transform.runner }
          column(:transform_enabled) { |pd| yes_no(pd.postrequisite_transform.enabled?) }
          column('') do |pd|
            link_to("Delete Dependency", transform_dependency_path(pd, source: :prerequisite_transform), method: :delete, data: { confirm: 'Are you sure you want to nuke this Transform Dependency?' })
          end
        end
      end
    end

    active_admin_comments

    render partial: 'admin/shared/history'
  end

  sidebar("Actions", only: :show) do
    ul do
      li link_to("Add Transform Validation", new_transform_validation_path(transform_id: resource.id))
      li link_to("Create New Postrequisite Transform", new_transform_path(workflow_id: resource.workflow_id, prerequisite_transform_id: resource.id))
    end
  end

  # FIXME - THE INTERACTIONS IN THIS FORM ARE TOO COMPLEX. MAYBE BREAK INTO MULTIPLE FORMS?
  form do |f|
    inputs 'Details' do
      # semantic_errors *f.object.errors.keys

      input :source, as: :hidden, input_html: { value: params[:source] }
      input :workflow_id, as: :hidden, input_html: { value: workflow_id_param_val }
      # We make this unchangeable because it's unclear what to do with dependencies if the User changes Workflow for the Transform on the fly.
      input :workflow, as: :select, collection: workflows_with_single_select, include_blank: params[:workflow_id].blank?, input_html: { disabled: f.object.persisted? }

      input :name, as: :string

      # FIXME - Want these to be radio buttons, but dunno how to get the JS to work
      input :runner, as: :select, collection: RunnerFactory::RUNNERS_FOR_SELECT, include_blank: false

      show_params_yaml_selector = ((f.object.new_record? || f.object.runner != 'RailsMigration') ? {} : { style: 'display:none' })
      input :params_yaml, as: :text, input_html: { rows: 10 }, wrapper_html: show_params_yaml_selector

      input :workflow_params_yaml, as: :text, collection: resource.workflow.params_yaml, input_html: { disabled: true, rows: 4 }, wrapper_html: show_params_yaml_selector, hint: "These params will be reverse-merged into the params_yaml in the previous field: there's no need to type them again."


      show_sql_selector = ((f.object.new_record? || f.object.runner != 'AutoLoad') ? {} : { style: 'display:none' })
      input :sql, as: :text, input_html: { rows: 40 }, wrapper_html: show_sql_selector

      file_display_h = (f.object.s3_file_required? ? {} : { style: 'display:none' })
      input :s3_file_name, as: :string, wrapper_html: file_display_h #, hint: "This file doesn't need to exist yet; you may upload it on Transform#show."

      input :enabled, hint: "Unchecking this causes this Transform to be skipped during a Run "
    end

    # We need the workflow id and we need to know that it won't change before we can present the list of allowed dependencies within the current workflow.
    if f.object.persisted? || workflow_id_param_val
      prereqs = f.object.available_prerequisite_transforms
      if prereqs.present?
        prereqs = group_prereqs(prereqs)
        inputs 'Dependencies' do
          prereq_id = params[:prerequisite_transform_id].to_i
          input :prerequisite_transforms, as: :check_boxes, collection: prereqs.map { |t| [t.name, t.id, checked: (t.id == prereq_id)] }, disabled: [nil]
        end
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
      super.includes(:workflow)
    end

    def action_methods
      result = super
      # Don't show the New button on the Transform page, so that creating a New Transform always takes you back to the Workflow page
      result -= ['new'] if action_name == 'index'
      result
    end

    def new
      @transform = Transform.new(workflow_id: params[:workflow_id].presence.try(:to_i))
    end

    def create
      # This hackaround is because Rails tries to save the join obj before the main obj has been saved (I think)
      # HOWEVER, the "has_many :through accepts_nested_attributes_for" thing works GREAT on Workflow#create for Workflow#notified_users ...
      #          and I can't suss what's different here. (The associations and inverse_ofs are identically structured.)
      #          My only guess is that the issue is b/c a Transform is at either end of the join.
      ids = params[:transform].delete(:prerequisite_transform_ids)&.reject(&:blank?)
      super do |success, failure|
        success.html do
          resource.prerequisite_transform_ids = ids
          resource.save!
          redirect_to transform_path(resource)
        end
      end
    end

    def update
      super do |success, failure|
        success.html do
          redirect_to((params[:source] || resource.source) == 'workflow' ? workflow_path(resource.workflow) : transform_path(resource))
        end
      end
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
