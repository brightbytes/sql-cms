# Produces runner modules that execute the supplied plan hash.
module RunnerFactory

  extend self

  def runner_for(runner_name)
    return nil if runner_name.blank?
    "RunnerFactory::#{runner_name}Runner".constantize rescue nil
  end

  # Introspect on the headers of the data file specified by the plan, create the table using the sql-identifier version of each header, and load the table.
  module AutoLoadRunner

    extend self

    def run(run:, plan_h:)
      raise "Not yet implemented"
    end
  end

  # Runs a Rails Migration
  module RailsMigrationRunner

    extend self

    def run(run:, plan_h:)
      # NOTE: params are discarded due to the heavy use of symbols in Rails Migrations
      run.eval_in_schema(plan_h[:sql])
    end
  end

  # Loads a table from a data file
  module CopyFromRunner

    extend self

    def run(run:, plan_h:)
      sql = Transform.interpolate(sql: plan_h[:sql], params: plan_h[:params])
      virtual_data_file = Datafile.new(plan_h[:data_file])
      open(virtual_data_file.s3_presigned_url) do |file|
        run.copy_from_in_schema(sql: sql, enumerable: file)
      end
    end
  end

  # Runs any DDL or DML SQL
  module SqlRunner

    extend self

    def run(run:, plan_h:)
      sql = Transform.interpolate(sql: plan_h[:sql], params: plan_h[:params])
      run.execute_in_schema(sql)
    end
  end

  # Unloads a table to a data file
  module CopyToRunner

    extend self

    def run(run:, plan_h:)
      sql = Transform.interpolate(sql: plan_h[:sql], params: plan_h[:params])
      virtual_data_file = Datafile.new(plan_h[:data_file])
      rd, wr = IO.pipe # I'm in love with IO.pipe!!!!!
      if fork
        wr.close
        virtual_data_file.s3_object.put(body: rd)
        rd.close
        Process.wait
      else
        rd.close
        run.copy_to_in_schema(sql: sql, writeable_io: wr)
        wr.close
      end
    end
  end

  # Redshift-specific version of CopyToRunner
  module UnloadRunner

    extend self

    def run(run:, plan_h:)
      raise "Not yet implemented"
    end
  end

  # Runs TransformValidations; internal-only Runner
  module ValidationRunner

    extend self

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

  # Runs DataQualityReports; internal-only Runner
  module DataQualityReportRunner

    extend self

    def run(run:, plan_h:)
      sql = Transform.interpolate(sql: plan_h[:sql], params: plan_h[:params])
      run.select_all_in_schema(sql)&.to_hash
    end
  end

end
