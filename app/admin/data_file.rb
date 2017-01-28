ActiveAdmin.register DataFile do

  scope "All", :with_deleted
  # For some reason, this doesn't use AR.all ...
  # scope "Undeleted Only", :all
  # ... hence this:
  scope "Undeleted Only", :sans_deleted, default: true
  scope "Deleted Only", :only_deleted

  actions :all

  config.add_action_item :undelete, only: :show, if: proc { resource.deleted? } do
    link_to "Undelete", undelete_data_file_path(resource), method: :put
  end

  permit_params :name, :metadata, :customer_id, :file_type, :s3_bucket_name, :s3_file_name

  filter :name, as: :string
  filter :customer, as: :select, collection: proc { Customer.order(:slug).all }
  filter :file_type, as: :select, collection: DataFile::FILE_TYPES
  filter :s3_bucket_name, as: :select

  # This may not work
  config.sort_order = 'customer.name_asc'

  index download_links: false do

    column :customer do |customer|
      link_to customer.name, customer_path(customer)
    end

  end

  # FIXME - Build a browser for files already on S3, using this example: https://www.topdan.com/ruby-on-rails/aws-s3-browser.html

  controller do

    def scoped_collection
      DataFile.joins(:customer)
    end

    def find_resource
      DataFile.with_deleted.find_by(id: params[:id])
    end

    def action_methods
      result = super
      # Don't show the destroy button if the DataFile is already destroyed, since a 2nd destroy will physically nuke the record
      result -= ['destroy'] if action_name == 'show' && resource.deleted?
      result
    end

  end


end
