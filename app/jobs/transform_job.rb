class TransformJob < ApplicationJob

  # FIXME - THIS ISN'T RETRY-SAFE.  TO MAKE IT SO, WE'D NEED TO ADD A NON-NULLABLE `transforms.table_name` FIELD, AND DO A `DELETE FROM :table_name` HERE
  #         BEFORE EXECUTING THE RUNNER
  def perform(run_id:, step_index:, step_id:)

    run = Run.find(run_id)

    transform_h = run.transform_plan(step_index: step_index, transform_id: step_id)

    if transform_h[:enabled]

      transform_runner = RunnerFactory.runner_for(transform_h[:runner])
      validation_runner = RunnerFactory.runner_for("Validation")

      success = run.with_run_step_log_tracking(step_type: 'transform', step_index: step_index, step_id: step_id) do
        result = { step_result: { rows_affected: transform_runner.run(run: run, plan_h: transform_h).cmd_tuples } }

        step_validation_failures = transform_h[:transform_validations].map do |transform_validation_h|
          validation_runner.run(run: run, transform_validation_h: transform_validation_h) if transform_validation_h[:enabled]
        end.compact.presence

        result.tap { |h| h.merge!(step_validation_failures: step_validation_failures) if step_validation_failures }
      end

    else

      success = run.with_run_step_log_tracking(step_type: 'transform', step_index: step_index, step_id: step_id) do
        { step_result: { transform_disabled: true } }
      end

    end

    run.notify_completed! unless success

  end

end
