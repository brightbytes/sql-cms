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

  def human_status(obj)
    case
    when obj.running_or_crashed?
      "<span style='color: blue'>Running (or Crashed)</span>".html_safe
    when obj.successful?
      "<span style='color: green'>Successful</span>".html_safe
    when obj.failed?
      "<span style='color: red'>Failed :-(</span>".html_safe
    end
  end

  def human_notification_status(run)
    status = run.notification_status.titleize
    color = (status == 'Sent' ? :green : :blue)
    "<span style='color: #{color}'>#{status}</span>".html_safe
  end

  # JSON stuff

  def pretty_print_as_json(json)
    JSON.pretty_generate(json.as_json).gsub(/\"(.+)\":/, '\1:').gsub(" ", "&nbsp;").gsub("\n", "<br />").html_safe if json.present?
  end

  # Kinda lame, but whatever
  def pretty_print_json(json)
    pretty_print_as_json(JSON.parse(json))
  end

  def sql_newlines_to_array(hash)
    hash = hash.with_indifferent_access
    hash[:sql] = hash[:sql].split("\n")
    hash
  end

  # Customer stuff

  # FIXME - DO SAME TREATMENT AS resource_workflow HERE; GOTTA RUN NOW
  def customers_with_single_select
    if param_val = params[:customer_id].presence&.to_i
      if customer = Customer.find_by(id: param_val)
        return [[customer.name, customer.id, selected: true]]
      end
    end
    Customer.order(:slug).map { |c| [c.name, c.id] }
  end

  # Workflow stuff

  def workflows_with_single_select
    if resource_workflow
      [[resource_workflow.name, resource_workflow.id, selected: true]]
    else
      Workflow.order(:slug).map { |c| [c.name, c.id] }
    end
  end

  def workflow_id_param_val
    @workflow_id_param_val ||= params[:workflow_id]&.to_i || resource.workflow.try(:id)
  end

  def resource_workflow
    @resource_workflow ||= resource.workflow || Workflow.find_by(id: params[:workflow_id])
  end

  # def transform_customer_id_param_val
  #   @transform_customer_id_param_val ||= params[:customer_id]&.to_i || resource_workflow&.customer_id
  # end

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
