ActiveAdmin.register RunStepLog do

  menu false

  actions :show, :destroy

  show do
    attributes_table do
      row :id
      row :run
      row :step # includes :step_name
      boolean_row :completed
      boolean_row :running
      boolean_row :successful
      row(:step_errors) { code(resource.step_errors) }
      row :created_at
      row :updated_at
    end

    active_admin_comments

    render partial: 'admin/shared/history'
  end

  controller do
    def destroy
      super do |success, failure|
        success.html { redirect_to(run_path(resource.run)) }
      end
    end
  end

end
