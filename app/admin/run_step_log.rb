ActiveAdmin.register RunStepLog do

  menu false

  actions :show

  show do
    attributes_table do
      row :id
      row :run
      row :workflow
      row :step_type
      row :likely_step
      row(:step_plan) { code(pretty_print_as_json(resource.step_plan)) }
      boolean_row :successful
      boolean_row :failed
      boolean_row :running_or_crashed
      row(:step_result) { code(pretty_print_as_json(resource.step_result)) }
      if resource.step_validation_failures.present?
        row(:step_validation_failures) do
          code(pretty_print_as_json(resource.step_validation_failures))
          para(link_to("Nuke and Rerun", nuke_and_rerun_run_step_log_path(resource)))
        end
      end
      if resource.step_exceptions.present?
        row(:step_exceptions) do
          code(pretty_print_as_json(resource.step_exceptions))
          para(link_to("Nuke and Rerun", nuke_and_rerun_run_step_log_path(resource)))
        end
      end
      row :created_at
      row :updated_at
    end

    active_admin_comments

    render partial: 'admin/shared/history'
  end

  member_action :nuke_and_rerun do
    RunStepLog.nuke_and_rerun!(resource)
    flash[:notice] = "Rerunning Step ..."
    redirect_to run_path(resource.run)
  end


end
