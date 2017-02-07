module RunnerFactory

  extend self

  def runner_for(runner_name)
    return nil if runner_name.blank?
    "#{runner}Runner".classify rescue nil
  end

  module AutoLoadRunner
    def run(run:, plan_h:)

    end
  end

  module CopyFromRunner
    def run(run:, plan_h:)

    end
  end

  module SqlRunner
    def run(run:, plan_h:)
      transform_sql = Transform.interpolate(sql: plan_h[:sql], params: plan_h[:params])
      run.execute_in_schema(sql)
    end
  end

  module CopyToRunner
    def run(run:, plan_h:)

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
