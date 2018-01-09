# frozen_string_literal: true

# This is a combination of a self-relogging (i.e. polling) job and a state machine for managing the execution of a Run.
# As such, I suppose it complects separate concerns.  Oh well.
class RunManagerJob < ApplicationJob

  POLLING_FREQUENCY = 3.seconds

  def perform(run_id)
    run = Run.find_by(id: run_id)
    return nil unless run
    return false if run.failed?

    if manage_state_machine(run)
      # Self-relog unless the state machine has finished.
      # FIXME - THERE'S THE POSSIBILITY THAT THIS COULD ENDLESSLY RECREATE THIS JOB FOR A GIVEN RUN IF THERE'S A BUG WITH THE RunStepLog MECHANISM;
      #         SO, THERE WILL NEED TO BE A NUMBER-OF-ITERATIONS TTL ON THIS RELOG FUNCTIONALITY, WHICH WILL REQUIRE A NEW Run FIELD
      #         HOWEVER, I HAVEN'T EVER RUN INTO THIS ISSUE, SO I'M NOT TOO WORRIED ABOUT IT
      RunManagerJob.set(wait: POLLING_FREQUENCY, queue: (run.use_redshift? ? :redshift : :default)).perform_later(run_id)
    end
  end

  private def manage_state_machine(run)

    case run.status

    when 'unstarted'
      # It's inconsistent that this is done here rather than a child job ... but, since this should be very fast, I prefer to skip the polling-frequency wait.
      run.create_schema
      run.update_attributes(status: "unstarted_ordered_transform_groups[0]")
      manage_state_machine(run) # ah, the glory of a brief affair with a recursive call

    when /unstarted_ordered_transform_groups\[(\d+)\]/
      step_index = $1.to_i
      transform_ids = run.transform_group_transform_ids(step_index)
      if transform_ids.present?
        transform_ids.each do |transform_id|
          TransformJob.set(queue: (run.use_redshift? ? :redshift : :default)).perform_later(run_id: run.id, step_index: step_index, step_id: transform_id)
        end
        run.update_attributes(status: "started_ordered_transform_groups[#{step_index}]")
      else
        run.update_attributes(status: "unstarted_workflow_data_quality_reports")
      end

    when /started_ordered_transform_groups\[(\d+)\]/
      step_index = $1.to_i
      if run.transform_group_successful?(step_index)
        next_step_index = step_index + 1
        if run.transform_group_transform_ids(next_step_index)
          run.update_attributes(status: "unstarted_ordered_transform_groups[#{next_step_index}]")
        else
          run.update_attributes(status: "unstarted_workflow_data_quality_reports")
        end
      end

    when 'unstarted_workflow_data_quality_reports'
      workflow_data_quality_report_ids = run.workflow_data_quality_report_ids
      if workflow_data_quality_report_ids.present?
        workflow_data_quality_report_ids.each do |workflow_data_quality_report_id|
          WorkflowDataQualityReportJob.set(queue: (run.use_redshift? ? :redshift : :default)).perform_later(run_id: run.id, step_id: workflow_data_quality_report_id)
        end
        run.update_attributes(status: "started_workflow_data_quality_reports")
      else
        return finish!(run)
      end

    when 'started_workflow_data_quality_reports'
      return finish!(run) if run.workflow_data_quality_reports_successful?

    end

    true
  end

  private

  def finish!(run)
    run.update_attributes(status: "finished")
    run.notify_completed!
    dump_execution_plan!(run) if run.exported_to_s3?
    return false # don't self-relog
  end

  # Arguably, this should be optional ... but personally I like to always have it.
  def dump_execution_plan!(run)
    plan_h = run.execution_plan
    s3_file = S3File.create(
      'export',
      s3_region_name: plan_h[:s3_region_name],
      s3_bucket_name: plan_h[:s3_bucket_name],
      s3_file_path: plan_h[:s3_file_path],
      s3_file_name: "execution_plan.json",
      run: run
    )
    # Tragically, we can't use IO.pipe b/c AWS needs to know the file size in advance so as to chunk the data when appropriate
    Tempfile.open(s3_file.s3_file_name, Dir.tmpdir, mode: IO::RDWR) do |stream|
      stream.write(run.execution_plan_dump)
      stream.rewind
      s3_file.upload(stream)
    end
  end
end
