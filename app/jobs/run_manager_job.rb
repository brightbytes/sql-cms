# This is a
class RunManagerJob < ApplicationJob

  POLLING_FREQUENCY = 10.seconds

  def perform(run_id)
    run = Run.find(run_id)

    return false if run.failed?

    case run.status

    when 'unstarted'
      # Sorry, but yes, it's totally awkward that the Run itself is considered to be the step that generates the schema.
      # And, it's inconsistent that this is done here rather than a child job ... but, since this should be very fast, I prefer to skip the polling-frequency wait.
      run.with_run_step_log_tracking(run) { run.create_schema }
      run.update_attribute(:status, "unstarted_ordered_transform_groups[0]")

    when /unstarted_ordered_transform_groups\[(\d+)\]/
      group_index = $1.to_i
      run.transform_group_transform_ids(group_index).each do |transform_id|
        TransformJob.perform_later(transform_id: transform_id)
      end
      run.update_attribute(:status, "started_ordered_transform_groups[#{group_index}]")

    when /started_ordered_transform_groups\[(\d+)\]/
      group_index = $1.to_i
      if run.transform_group_completed?(group_index)
        next_group_index = group_index + 1
        if transform_group_transform_ids(next_group_index)
          run.update_attribute(:status, "ordered_transform_groups[#{next_group_index}]")
        else
          run.update_attribute(:status, "unstarted_data_quality_reports")
        end
      end

    when 'unstarted_data_quality_reports'
      run.data_quality_report_ids.each do |data_quality_report_id|
        DataQualityReportJob.perform_later(data_quality_report_id)
      end
      run.update_attribute(:status, "started_data_quality_reports")

    when 'started_data_quality_reports'
      if run.data_quality_reports_completed?
        run.update_attribute(:status, "finished")
        return
      end

    end

    RunManagerJob.set(wait: POLLING_FREQUENCY).perform_later(run_id)
  end
end
