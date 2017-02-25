# Produces runner modules that execute the supplied plan hash.
module RunnerFactory

  extend self

  RUNNERS = %w(RailsMigration AutoLoad CopyFrom Sql CopyTo Unload).freeze

  IMPORT_S3_FILE_RUNNERS = %w(AutoLoad CopyFrom).freeze

  EXPORT_S3_FILE_RUNNERS = %w(CopyTo Unload).freeze

  S3_FILE_RUNNERS = (IMPORT_S3_FILE_RUNNERS + EXPORT_S3_FILE_RUNNERS).freeze

  NON_S3_FILE_RUNNERS = %w(RailsMigration Sql).freeze

  def runner_for(runner_name)
    return nil if runner_name.blank?
    "RunnerFactory::#{runner_name}Runner".constantize rescue nil
  end

  # Introspect on the headers of the data file specified by the plan, create the table using the sql-identifier version of each header, and load the table.
  # Obviously, requires that the source file have a header row.
  module AutoLoadRunner

    extend self

    def run(run:, plan_h:)
      # FIXME - THIS IS CHEESEY, AND BEGS FOR AN OBJECT TO WRAP THE S3 ATTS
      virtual_transform = Transform.new(
        s3_region_name: plan_h[:s3_region_name],
        s3_bucket_name: plan_h[:s3_bucket_name],
        s3_file_path: plan_h[:s3_file_path],
        s3_file_name: plan_h[:s3_file_name],
      )
      open(virtual_transform.s3_presigned_url) do |stream|
        table_name = plan_h[:params][:table_name]
        raise "The AutoLoad runner requires a :table_name param" unless table_name.present?

        begin
          # We wrap in a CSV obj only to get automatic parsing of quotes/commas/escapes for the header ... and discard the CSV object after that sole use
          csv_wrapped_stream = CSV.new(stream)
          header_a = csv_wrapped_stream.gets
          raise "Empty header line for #{virtual_transform.s3_public_url}" unless header_a.present?

          header_a.map! { |header| Workflow.to_sql_identifier(header) }

          # FIXME - ADD A FEATURE FOR AUTO-ADDING INDEXES VIA PARAMS
          migration_column_s = header_a.map { |header| "t.string :#{header}" }.join("\n  ")
          migration_s = <<-SQL.strip_heredoc
            create_table :#{table_name} do |t|
              #{migration_column_s}
            end
          SQL
          run.eval_in_schema(migration_s)

          header_s = header_a.join(', ')
          sql = "COPY #{table_name} (#{header_s}) FROM STDIN WITH CSV"

          run.copy_from_in_schema(sql: sql, enumerable: stream)

        ensure
          csv_wrapped_stream.close # not sure this is actually required

        end
      end
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
      # FIXME - THIS IS CHEESEY, AND BEGS FOR AN OBJECT TO WRAP THE S3 ATTS
      virtual_transform = Transform.new(
        s3_region_name: plan_h[:s3_region_name],
        s3_bucket_name: plan_h[:s3_bucket_name],
        s3_file_path: plan_h[:s3_file_path],
        s3_file_name: plan_h[:s3_file_name],
      )
      open(virtual_transform.s3_presigned_url) do |stream|
        run.copy_from_in_schema(sql: sql, enumerable: stream)
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
      # FIXME - THIS IS CHEESEY, AND BEGS FOR AN OBJECT TO WRAP THE S3 ATTS
      virtual_transform = Transform.new(
        s3_region_name: plan_h[:s3_region_name],
        s3_bucket_name: plan_h[:s3_bucket_name],
        s3_file_path: plan_h[:s3_file_path],
        s3_file_name: plan_h[:s3_file_name],
      )

      # Tragically, we can't use IO.pipe b/c AWS needs to know the file size in advance so as to chunk the data when appropriate
      Tempfile.open(virtual_transform.s3_file_name, Dir.tmpdir, mode: IO::RDWR) do |stream|
        run.copy_to_in_schema(sql: sql, writeable_io: stream).tap do
          stream.rewind
          virtual_transform.s3_object(run).put(body: stream)
        end
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
