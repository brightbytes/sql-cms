# FIXME - AA DOESN'T AUTO-RELOAD THIS FILE
module ApplicationHelper

  def yes_no(val, options = {})
    if val
      if color = options[:yes_color]
        "<span style='color: #{color}'>Yes</span>".html_safe
      else
        "Yes"
      end
    else
      if color = options[:no_color]
        "<span style='color: #{color}'>No</span>".html_safe
      else
        "No"
      end
    end
  end

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
    @transform_customer_id_param_val ||= params[:customer_id]&.to_i || resource_workflow&.customer_id
  end

  def data_files_for_workflow
    @data_files_for_workflow ||=
      if transform_customer_id_param_val
        DataFile.where(customer_id: transform_customer_id_param_val)
      else
        []
      end
  end

  # TranformValidations stuff

  def transform_id_param_val
    @transform_id_param_val ||= params[:transform_id]&.to_i || resource.transform.try(:id)
  end

  def resource_transform
    @resource_transform ||= resource.transform || Transform.find_by(id: params[:transform_id])
  end

  def transforms_with_preselect(disabled = false)
    if disabled
      [[resource_transform.name, resource_transform.id, selected: true]]
    else
      Transform.order(:name).map { |c| (c.id == transform_id_param_val) ? [c.name, c.id, selected: true] : [c.name, c.id] }
    end
  end

  def parent_transform_path
    @parent_transform_path ||= transform_path(id: transform_id_param_val)
  end

end
