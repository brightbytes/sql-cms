# FIXME - AA DOESN'T AUTO-RELOAD THIS FILE, AND IT'S ABSOLUTELY KILLING ME THAT GOOGLE & STACK OVERFLOW ARE NO HELP!!!!!!!!!!
module ::ActiveAdmin::ViewsHelper

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
    return nil unless obj
    case
    when obj.running_or_crashed?
      "<span style='color: blue'>Running</span>".html_safe
    when obj.successful?
      "<span style='color: green'>Successful</span>".html_safe
    when obj.failed?
      "<span style='color: red'>Failed :-(</span>".html_safe
    end
  end

  def human_notification_status(run)
    return nil unless run
    status = run.notification_status.titleize
    color = (status == 'Sent' ? :green : :blue)
    "<span style='color: #{color}'>#{status}</span>".html_safe
  end

  def human_duration(o)
    Time.at(o.duration_seconds).getutc.strftime("%H:%M:%S") if o
  end

  # JSON stuff

  def pretty_print_as_json(json)
    # All the screwing-around with `\\r?\\n` is so that multi-line JSON attribute values end up being broken into multiple lines in the display
    JSON.pretty_generate(json).gsub(/\"(.+)\":/, '\1:').gsub(/"(.+\\r?\\n)/, '"\\r\\n\1').gsub(/\\r?\\n/, "<br />").html_safe if json.present?
  end

  def sql_newlines_to_array(hash)
    hash = hash.with_indifferent_access
    hash[:sql] = hash[:sql].split("\n")
    hash
  end

  # Customer stuff

  # Currently, this is only passed when clicking Create New WorkflowConfiguration from the Customer page.
  def customer_id_from_param
    params[:customer_id].presence&.to_i
  end

  # FIXME - DO SAME TREATMENT AS resource_workflow HERE; GOTTA RUN NOW
  def customers_with_single_select
    if param_val = customer_id_from_param
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

  def parent_workflow_path
    @parent_workflow_path ||= workflow_path(id: workflow_id_param_val)
  end

  # Workflow Config stuff

  def workflow_configuration_id_param_val
    @workflow_configuration_id_param_val ||= resource.workflow_configuration.try(:id)
  end

  # TranformValidations stuff

  def transform_id_param_val
    @transform_id_param_val ||= params[:transform_id]&.to_i || resource.transform.try(:id)
  end

  def parent_transform_path
    @parent_transform_path ||= transform_path(id: transform_id_param_val)
  end

  # Transform stuff

  def group_prereqs(prereqs)
    [].tap do |grouped_prereqs|
      step_index = 0
      step_index_subtractor = 0
      plan = ExecutionPlan.create(resource.workflow.workflow_configurations.first || WorkflowConfiguration.new(workflow: resource.workflow))
      while transform_ids = plan.transform_group_transform_ids(step_index) do
        prereq_group = []
        prereqs.each { |prereq| prereq_group << prereq if prereq.id.in?(transform_ids) }
        if prereq_group.present?
          grouped_prereqs << Transform.new(name: "_____TRANSFORM GROUP #{step_index - step_index_subtractor}_____")
          grouped_prereqs << prereq_group
        else
          step_index_subtractor += 1
        end
        step_index += 1
      end
      grouped_prereqs.flatten!
    end
  end

end
