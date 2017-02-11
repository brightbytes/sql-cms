ActiveAdmin.register DataFile do

  menu priority: 15

  actions :all

  permit_params :name, :customer_id, :file_type, :supplied_s3_url, :s3_region_name, :s3_bucket_name, :s3_file_name

  filter :name, as: :string
  filter :customer, as: :select, collection: proc { Customer.order(:slug).all }
  filter :file_type, as: :select, collection: DataFile::FILE_TYPES
  filter :s3_region_name, as: :select
  filter :s3_bucket_name, as: :select

  config.sort_order = 'customers.name_asc'

  index download_links: false do
    # id_column
    column(:name) { |data_file| auto_link(data_file) }
    column(:customer)
    column(:file_type)
    column(:s3_region_name)
    column(:s3_bucket_name)
    column(:s3_file_name)
    column(:s3_file_exists?) { |data_file| yes_no(data_file.s3_file_exists?, yes_color: :green, no_color: :red) }
  end

  show do
    attributes_table do
      row :id
      row :name
      row :customer

      row :file_type

      row :s3_region_name
      row :s3_bucket_name
      row :s3_file_name
      row(:s3_file_exists?) { yes_no(resource.s3_file_exists?, yes_color: :green, no_color: :red) }

      row :created_at
      row :updated_at
    end

    active_admin_comments

    render partial: 'admin/shared/history'
  end

  # FIXME - Build a browser for files already on S3, from which to select, perhaps using this example: https://www.topdan.com/ruby-on-rails/aws-s3-browser.html

  form do |f|
    inputs 'Details' do
      input :customer, as: :select, collection: customers_with_preselect
      input :name, as: :string

      input :file_type, as: :select, collection: DataFile::FILE_TYPES

      if action_name.in?(['create', 'new'])
        # FIXME: Only show this when :file_type is :import ...
        input :supplied_s3_url, label: "S3 File URL", required: true , hint: "You may use either https:// format or s3:// format for this URL"

        # FIXME: When :file_type is :export, show these instead:
        # input :s3_region_name, as: :string
        # input :s3_bucket_name, as: :string
        # input :s3_file_name, as: :string

      else
        input :s3_region_name, as: :string # This should be a drop-down
        input :s3_bucket_name, as: :string
        input :s3_file_name, as: :string
      end
    end

    actions do
      action(:submit)
      path = (params[:source] == 'customer' ? customer_path(params[:customer_id]) : f.object.new_record? ? data_files_path : data_file_path(f.object))
      cancel_link(path)
    end
  end

  controller do

    def scoped_collection
      super.joins(:customer)
    end

    def destroy
      super do |success, failure|
        success.html { redirect_to(params[:source] == 'customer' ? customer_path(resource.customer) : data_files_path) }
      end
    end

  end

end
