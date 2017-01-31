ActiveAdmin.register Notification do

  menu false

  actions :new, :create, :destroy

  permit_params :workflow_id, :user_id

  form do |f|
    # For debugging:
    semantic_errors *f.object.errors.keys
    inputs 'Details' do
      input :workflow_id, as: :hidden, input_html: { value: workflow_id_param_val }
      input :workflow, as: :select, collection: workflows_with_preselect, input_html: { disabled: true }
      input :user, as: :select, collection: users_sans_preselected(notification_workflow)
    end
    actions do
      action(:submit)
      cancel_link(parent_workflow_path)
    end
  end

  controller do

    def create
      super do |success, failure|
        success.html { redirect_to(parent_workflow_path) }
      end
    end

    def destroy
      super do |success, failure|
        success.html { redirect_to(parent_workflow_path) }
      end
    end
  end

end
