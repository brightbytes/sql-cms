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
      row(:plan_source_step) do
        text_node(auto_link(run_step_log.plan_source_step))
        # FIXME - Add Edit Link Here
      end

      row(:human_status) { human_status(resource) }

      row(:duration) { Time.at(resource.duration_seconds).getutc.strftime("%H:%M:%S") }

      row(:step_plan) { code(pretty_print_as_json(resource.step_plan)) }

      row(:step_result) { code(pretty_print_as_json(resource.step_result)) } if resource.step_result.present?
      row(:step_validation_failures) { code(pretty_print_as_json(resource.step_validation_failures)) } if resource.step_validation_failures.present?
      row(:step_exceptions) { code(pretty_print_as_json(resource.step_exceptions)) } if resource.step_exceptions.present?

      row :created_at
      row :updated_at
    end

    active_admin_comments

    render partial: 'admin/shared/history'
  end

end
