ActiveAdmin.register User, sort_order: "id_asc" do

  menu priority: 100 # Put this at the far right of the display

  scope "All", :with_deleted
  # For some reason, this doesn't use AR.all ...
  # scope "Undeleted Only", :all
  # ... hence this:
  scope "Undeleted Only", :sans_deleted, default: true
  scope "Deleted Only", :only_deleted

  filter :email
  filter :first_name
  filter :last_name

  index(download_links: false) do
    # selectable_column
    id_column
    column(:full_name, sortable: :first_name) { |user| auto_link(user) }
    column(:email, sortable: :email) { |user| mail_to user.email }
    column :current_sign_in_at
    column :sign_in_count
    # column :deleted_at
  end

  show title: :full_name do
    attributes_table do
      row :id
      row :first_name
      row :last_name
      row(:email) { mail_to(user.email) }
      # If we add Devise confirmable
      # row(:unconfirmed_email) { mail_to(user.unconfirmed_email) }
      # row("Enabled?") { user.enabled? ? "Yes" : "<span style='color: red'>No</span>".html_safe }
      row :reset_password_sent_at
      row :remember_created_at
      row :sign_in_count
      row :current_sign_in_at
      row :current_sign_in_ip
      row :last_sign_in_at
      row :last_sign_in_ip

      row :created_at
      row :updated_at
      row :deleted_at
    end

    active_admin_comments

    render partial: 'admin/shared/history'
  end

  permit_params :email, :first_name, :last_name, :password, :password_confirmation

  form do |f|
    inputs "Admin Details" do
      input :first_name
      input :last_name
      input :email
      input :password
      input :password_confirmation, required: true
    end
    actions
  end

  controller do

    def find_resource
      User.with_deleted.find_by(id: params[:id])
    end

    def action_methods
      result = super
      # Don't show the destroy button if the User is already destroyed, since a 2nd destroy will physically nuke the record
      result -= ['destroy'] if action_name == 'show' && resource.deleted?
      result
    end

    def update
      user_params = params[:user]
      if user_params[:password].blank?
        user_params.delete(:password)
        user_params.delete(:password_confirmation)
      end
      super
    end

  end

  config.add_action_item :undelete, only: :show, if: proc { resource.deleted? } do
    link_to "Undelete", undelete_user_path(resource), method: :put
  end

  member_action :undelete, method: :put do
    resource.recover
    flash[:notice] = "User Restored!"
    redirect_to user_path(resource)
  end

end
