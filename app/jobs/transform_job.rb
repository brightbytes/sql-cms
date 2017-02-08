class TransformJob < ApplicationJob

  def perform(run_id:, step_index:, step_id:)

    run = Run.find(run_id)

    transform_h = run.transform_plan(step_index: step_index, transform_id: step_id)
    transform_runner = RunnerFactory.runner_for(transform_h[:runner])
    validation_runner = RunnerFactory.runner_for("Validation")
    run.with_run_step_log_tracking(step_type: 'transform', step_index: step_index, step_id: step_id) do
      transform_runner.run(run: run, plan_h: transform_h)

      transform_h[:transform_validations].map do |transform_validation_h|
        validation_runner.run(run: run, transform_validation_h: transform_validation_h)
      end.compact.presence
    end

  end

end
