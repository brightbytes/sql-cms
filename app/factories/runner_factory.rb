# Produces runner modules that execute the supplied plan hash.
module RunnerFactory

  extend self

  def runner_for(runner_name)
    return nil if runner_name.blank?
    "#{runner}Runner".classify rescue nil
  end

  # Introspect on the headers of the data file specified by the plan, create the table using the sql-identifier version of each header, and load the table.
  module AutoLoadRunner
    def run(run:, plan_h:)
      raise "Not yet implemented"
    end
  end

  # Loads a table from a data file
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

  # Unloads a table to a data file
  module CopyToRunner
    def run(run:, plan_h:)

    end
  end

  # Redshift-specific version of CopyToRunner
  module UnloadRunner
    def run(run:, plan_h:)
      raise "Not yet implemented"
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
