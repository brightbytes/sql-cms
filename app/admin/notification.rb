ActiveAdmin.register Notification do

  menu false

  actions :destroy

  controller do

    def destroy
      super do |success, failure|
        success.html { redirect_to(parent_workflow_path) }
      end
    end
  end

end
