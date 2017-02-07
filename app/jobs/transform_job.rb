class TransformJob < ApplicationJob

  def perform(run_id:, step_index:, step_id:)

    run = Run.find(run_id)

    run.with_run_step_log_tracking(step_name: "ordered_transform_groups", step_index: step_index, step_id: step_id) do
      transform_h = run.transform_plan(step_index:, transform_id:)
      transform_runner = runner_for(transform_h[:runner])
      transform_runner.run(run: run, transform_h: transform_h)

      transform_h[:transform_validations].map do |transform_validation_h|
        ValidationRunner.run(run: run, transform_validation_h: transform_validation_h)
      end.compact.presence
    end

  end

  private

  def runner_for(runner)
    return nil if runner.blank?
    "#{runner}Runner".classify
  end

  module AutoLoadRunner
    def run(run:, transform_h:)

    end
  end

  module CopyFromRunner
    def run(run:, transform_h:)

    end
  end

  module SqlRunner
    def run(run:, transform_h:)
      transform_sql = Transform.interpolate(sql: transform_h[:sql], params: transform_h[:params])
      run.execute_in_schema(sql)
    end
  end

  module CopyToRunner
    def run(run:, transform_h:)

    end
  end

  module ValidationRunner
    def run(run:, transform_validation_h:)
      transform_validation_sql = TransformValidation.interpolate(sql: transform_validation_h[:sql], params: transform_validation_h[:params])
      if ids = run.select_values_in_schema(transform_validation_sql).presence
        {
          failed_validation_name: transform_validation_h[:name],
          failed_validation_sql: transform_validation_sql,
          ids_failing_validation: ids
        }
      end
    end
  end
end
