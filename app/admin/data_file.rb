ActiveAdmin.register DataFile do

  menu priority: 25

  actions :all

  permit_params :name, :workflow_id, :file_type, :supplied_s3_url, :s3_region_name, :s3_bucket_name, :s3_file_path, :s3_file_name

  filter :name, as: :string
  filter :workflow, as: :select, collection: proc { Workflow.order(:slug).all }
  filter :file_type, as: :select, collection: DataFile::FILE_TYPES
  filter :s3_region_name, as: :select
  filter :s3_bucket_name, as: :select

  config.sort_order = 'workflows.slug_asc,name_asc'

  index download_links: false do
    column(:name) { |data_file| auto_link(data_file) }
    column(:workflow)
    column(:file_type)
    column(:s3_region_name)
    column(:s3_bucket_name)
    column(:s3_file_path)
    column(:s3_file_name)
    column(:s3_file_exists?) { |data_file| data_file.export? ? 'n/a' : yes_no(data_file.s3_file_exists?, yes_color: :green, no_color: :red) }
  end

  show do
    attributes_table do
      row :id
      row :name
      row :workflow

      row :file_type

      row :s3_region_name
      row :s3_bucket_name
      row :s3_file_path
      row :s3_file_name
      row(:s3_file_exists?) { yes_no(resource.s3_file_exists?, yes_color: :green, no_color: :red) } if data_file.import?

      row :created_at
      row :updated_at
    end

    panel 'Transforms Using this DataFile' do
      sort = params[:order].try(:gsub, '_asc', ' ASC').try(:gsub, '_desc', ' DESC') || :name
      table_for(resource.transforms.order(sort), sortable: true) do
        column(:name, sortable: :name) { |transform| auto_link(transform) }
        column(:runner, sortable: :runner) { |transform| transform.runner }
      end
    end

    active_admin_comments

    render partial: 'admin/shared/history'
  end

  form do |f|
    inputs 'Details' do
      input :workflow, as: :select, collection: workflows_with_preselect
      input :name, as: :string

      creating = action_name.in?(['create', 'new'])

      input :file_type, as: :select, collection: DataFile::FILE_TYPES, input_html: { disabled: !creating }

      # FIXME - Build a browser for files already on S3, from which to select, perhaps using this example: https://www.topdan.com/ruby-on-rails/aws-s3-browser.html

      if creating

        # For import files ...
        input :supplied_s3_url, label: "S3 File URL", required: true , hint: "You may use either https:// format or s3:// format for this URL"

        # For export files ...
        input :s3_region_name, as: :string, wrapper_html: { style: 'display:none' } # should be a drop-down
        input :s3_bucket_name, as: :string, wrapper_html: { style: 'display:none' }
        input :s3_file_path, as: :string, wrapper_html: { style: 'display:none' }
        input :s3_file_name, as: :string, wrapper_html: { style: 'display:none' }

      else
        input :s3_region_name, as: :string # This should be a drop-down
        input :s3_bucket_name, as: :string
        input :s3_file_path, as: :string
        input :s3_file_name, as: :string
      end
    end

    actions do
      action(:submit)
      path = (params[:source] == 'workflow' ? customer_path(params[:workflow_id]) : f.object.new_record? ? data_files_path : data_file_path(f.object))
      cancel_link(path)
    end
  end

  controller do

    def action_methods
      result = super
      # Don't show the destroy button if the DataFile is used by a transform
      result -= ['destroy'] if action_name == 'show' && resource.used?
      result
    end

    def scoped_collection
      super.joins(:workflow)
    end

    def destroy
      super do |success, failure|
        success.html { redirect_to(params[:source] == 'workflow' ? customer_path(resource.workflow) : data_files_path) }
      end
    end

  end

end
