class WorkflowDataQualityReportJob < ApplicationJob

  def perform(run_id:, step_id:)

    run = Run.find(run_id)

    workflow_data_quality_report_h = run.workflow_data_quality_report_plan(step_id)
    workflow_data_quality_report_runner = RunnerFactory.runner_for('WorkflowDataQualityReport')

    success = run.with_run_step_log_tracking(step_type: "workflow_data_quality_report", step_id: step_id) do
      { step_result: workflow_data_quality_report_runner.run(run: run, plan_h: workflow_data_quality_report_h) }
    end

    run.notify_completed! unless success
  end
end
