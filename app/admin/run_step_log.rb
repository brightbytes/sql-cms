ActiveAdmin.register RunStepLog do

  menu false

  actions :show

  show do
    attributes_table do
      row :id
      row :run
      row :step_type
      row(:step_plan) { code(pretty_print_as_json(resource.step_plan)) }
      boolean_row :completed
      boolean_row :running
      boolean_row :successful
      row(:step_result) { code(pretty_print_as_json(resource.step_result)) }
      row(:step_validation_failures) { code(pretty_print_as_json(resource.step_validation_failures)) }
      row(:step_exceptions) { code(pretty_print_as_json(resource.step_exceptions)) }
      row :created_at
      row :updated_at
    end

    active_admin_comments

    render partial: 'admin/shared/history'
  end

end
