# This is a combination of a self-relogging (i.e. polling) job and a state machine for managing the execution of a Run.
# As such, I suppose it complects separate concerns.  Oh well.
class RunManagerJob < ApplicationJob

  POLLING_FREQUENCY = 10.seconds

  def perform(run_id)
    run = Run.find(run_id)

    return false if run.failed?

    if manage_state_machine(run)
      RunManagerJob.set(wait: POLLING_FREQUENCY).perform_later(run_id)
    end
  end

  private def manage_state_machine(run)
    case run.status

    when 'unstarted'
      # Sorry, but yes, it's totally awkward that the Run itself is considered to be the step that generates the schema.
      # And, it's inconsistent that this is done here rather than a child job ... but, since this should be very fast, I prefer to skip the polling-frequency wait.
      run.with_run_step_log_tracking(run) { run.create_schema }
      run.update_attribute(:status, "unstarted_ordered_transform_groups[0]")
      manage_state_machine(run) # ah, the glory of a brief affair with a recursive call

    when /unstarted_ordered_transform_groups\[(\d+)\]/
      step_index = $1.to_i
      run.transform_group_transform_ids(step_index).each do |transform_id|
        TransformJob.perform_later(run_id: run.id, step_index: step_index, step_id: transform_id)
      end
      run.update_attribute(:status, "started_ordered_transform_groups[#{step_index}]")

    when /started_ordered_transform_groups\[(\d+)\]/
      step_index = $1.to_i
      if run.transform_group_successfully_completed?(step_index)
        next_step_index = step_index + 1
        if transform_group_transform_ids(next_step_index)
          run.update_attribute(:status, "ordered_transform_groups[#{next_step_index}]")
        else
          run.update_attribute(:status, "unstarted_data_quality_reports")
        end
      end

    when 'unstarted_data_quality_reports'
      run.data_quality_report_ids.each do |data_quality_report_id|
        DataQualityReportJob.perform_later(run_id: run.id, step_id: data_quality_report_id)
      end
      run.update_attribute(:status, "started_data_quality_reports")

    when 'started_data_quality_reports'
      if run.data_quality_reports_successfully_completed?
        run.update_attribute(:status, "finished")
        return false
      end

    end

    true
  end

end
