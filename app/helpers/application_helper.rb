# FIXME - AA DOESN'T AUTO-RELOAD THIS FILE
module ApplicationHelper

  # JSON stuff

  def pretty_print_as_json(json)
    JSON.pretty_generate(json.as_json).gsub(/\"(.+)\":/, '\1:').gsub(" ", "&nbsp;").gsub("\n", "<br />").html_safe if json.present?
  end

  # Kinda lame, but whatever
  def pretty_print_json(json)
    pretty_print_as_json(JSON.parse(json))
  end

  # Customer stuff

  def customers_with_preselect
    param_val = params[:customer_id].to_i
    Customer.order(:slug).map { |c| (c.id == param_val) ? [c.name, c.id, selected: true] : [c.name, c.id] }
  end

  # Workflow stuff

  def workflows_with_preselect(disabled = false)
    if disabled
      [[resource_workflow.name, resource_workflow.id, selected: true]]
    else
      Workflow.order(:slug).map { |c| (c.id == workflow_id_param_val) ? [c.name, c.id, selected: true] : [c.name, c.id] }
    end
  end

  def workflow_id_param_val
    @workflow_id_param_val ||= params[:workflow_id]&.to_i || resource.workflow.try(:id)
  end

  def resource_workflow
    @resource_workflow ||= resource.workflow || Workflow.find_by(id: params[:workflow_id])
  end

  def transform_customer_id_param_val
    @transform_customer_id_param_val ||= params[:customer_id]&.to_i || resource_workflow.customer_id
  end

  def data_files_for_workflow
    @data_files_for_workflow ||=
      if transform_customer_id_param_val
        DataFile.where(customer_id: transform_customer_id_param_val)
      else
        []
      end
  end

  def parent_workflow_path
    @parent_workflow_path ||= workflow_path(id: workflow_id_param_val)
  end

  # Possibly reusable code, for later

  # def notifiable_user_ids(workflow)
  #   User.pluck(:id) - workflow.notifications.pluck(:user_id)
  # end

  # def any_notifiable_users?(workflow)
  #   notifiable_user_ids(workflow).present?
  # end

  # def users_sans_preselected(workflow)
  #   User.where(id: notifiable_user_ids(workflow)).order(:first_name, :last_name)
  # end

  # def users_with_preselect
  #   param_val = params[:user_id].to_i
  #   User.order(:first_name, :last_name).map { |c| (c.id == param_val) ? [c.full_name, c.id, selected: true] : [c.full_name, c.id] }
  # end

end
