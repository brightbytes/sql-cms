ActiveAdmin.register RunStepLog do

  menu false

  actions :show

  show do
    attributes_table do
      row :id
      row :run
      row :workflow
      row :step_type
      row :step_index
      row :step_id
      row :likely_step
      row(:human_status) { human_status(resource) }
      row(:step_plan) { code(pretty_print_as_json(resource.step_plan)) }
      row(:step_result) { code(pretty_print_as_json(resource.step_result)) } if resource.step_result.present?
      row(:step_validation_failures) { code(pretty_print_as_json(resource.step_validation_failures)) } if resource.step_validation_failures.present?
      row(:step_exceptions) { code(pretty_print_as_json(resource.step_exceptions)) } if resource.step_exceptions.present?
      if Rails.env.development? && (resource.step_validation_failures.present? || resource.step_exceptions.present?)
        row(:dev_only_action) { link_to("Nuke and Rerun (with same Plan!)", nuke_and_rerun_run_step_log_path(resource)) }
      end
      row :created_at
      row :updated_at
    end

    active_admin_comments

    render partial: 'admin/shared/history'
  end

  # This is only useful for dev debugging
  member_action :nuke_and_rerun do
    RunStepLog.nuke_and_rerun!(resource)
    flash[:notice] = "Rerunning Step ..."
    redirect_to run_path(resource.run)
  end

end
