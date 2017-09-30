ActiveAdmin.register Notification do

  menu false

  actions :destroy

  controller do

    def destroy
      super do |success, failure|
        # These only ever come from workflows
        success.html { redirect_to(workflow_configuration_path(id: workflow_configuration_id_param_val)) }
      end
    end
  end

end
