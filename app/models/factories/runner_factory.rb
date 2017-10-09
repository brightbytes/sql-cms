# Produces runner modules that execute the supplied plan hash.
module RunnerFactory

  extend self

  RUNNERS = %w(RailsMigration AutoLoad CopyFrom Sql CopyTo Unload).freeze

  NEW_TRANSFORM_RUNNERS_FOR_SELECT = [
    [' Auto-load', 'AutoLoad'],
    [' COPY ... FROM', 'CopyFrom'],
    [' COPY ... TO', 'CopyTo'],
    [' Rails Migration', 'RailsMigration'],
    [' SQL', 'Sql'],
    [' UNLOAD', 'Unload']
  ]

  RUNNERS_FOR_SELECT = [
    [' SQL', 'Sql'],
    [' Rails Migration', 'RailsMigration'],
    [' Auto-load', 'AutoLoad'],
    [' COPY ... FROM', 'CopyFrom'],
    [' COPY ... TO', 'CopyTo'],
    [' UNLOAD', 'Unload']
  ]

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
      s3_file = S3File.create(
        'import',
        s3_region_name: plan_h[:s3_region_name],
        s3_bucket_name: plan_h[:s3_bucket_name],
        s3_file_path: plan_h[:s3_file_path],
        s3_file_name: plan_h[:s3_file_name]
      )

      table_name = plan_h[:params].fetch(:table_name, nil)
      raise "The AutoLoad runner requires a :table_name param" unless table_name.present?

      url = s3_file.s3_presigned_url
      raise "Unable to locate #{s3_file}!" unless url

      open(url) do |stream|
        begin
          # We wrap in a CSV obj only to get automatic parsing of quotes/commas/escapes for the header ... and discard the CSV object after that sole use
          csv_wrapped_stream = CSV.new(stream)
          header_a = csv_wrapped_stream.gets
          raise "Empty header line for #{s3_file.s3_public_url}" unless header_a.present?

          header_a.map! { |header| Workflow.to_sql_identifier(header) }

          # The :name_type_map & :indexed_columns params are merely POC about how to configure a schema; they could both be far more expressive/useful
          # Build them out as needed, and also introduce the ability to define a schema in its entirity via a JSON config
          migration_column_s = header_a.map do |header|
            column_type = plan_h[:params].fetch(:name_type_map, nil)&.fetch(header.to_sym, nil) || :string
            "t.#{column_type} :#{header}"
          end.join("\n  ")

          if indexes = plan_h[:params].fetch(:indexed_columns, nil)
            indexes_s = indexes.map { |column| "add_index :#{table_name}, :#{column}\n" }
          end

          migration_s = <<-SQL.strip_heredoc
            create_table :#{table_name} do |t|
              #{migration_column_s}
            end
            #{indexes_s}
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

  # Imports a table from a data file
  module CopyFromRunner

    extend self

    def run(run:, plan_h:)
      # FIXME - ALLOW THIS TO WORK IN REDSHIFT, THOUGH OBVIOUSLY BY CONDITIONALIZING THE LAST LINES.
      raise "CopyFromRunner doesn't work in Redshift." if run.use_redshift?

      s3_file = S3File.create(
        'import',
        s3_region_name: plan_h[:s3_region_name],
        s3_bucket_name: plan_h[:s3_bucket_name],
        s3_file_path: plan_h[:s3_file_path],
        s3_file_name: plan_h[:s3_file_name]
      )

      url = s3_file.s3_presigned_url
      raise "Unable to locate #{s3_file}!" unless url

      open(url) { |stream| run.copy_from_in_schema(sql: plan_h[:interpolated_sql], enumerable: stream) }
    end
  end

  # Runs any DDL or DML SQL
  module SqlRunner

    extend self

    def run(run:, plan_h:)
      run.execute_in_schema(plan_h[:interpolated_sql])
    end
  end

  # Exports a table to a data file
  module CopyToRunner

    extend self

    def run(run:, plan_h:)
      raise "CopyToRunner doesn't work in Redshift." if run.use_redshift?

      s3_file = S3File.create(
        'export',
        s3_region_name: plan_h[:s3_region_name],
        s3_bucket_name: plan_h[:s3_bucket_name],
        s3_file_path: plan_h[:s3_file_path],
        s3_file_name: plan_h[:s3_file_name],
        run: run
      )

      # Tragically, we can't use IO.pipe b/c AWS needs to know the file size in advance so as to chunk the data when appropriate
      Tempfile.open(s3_file.s3_file_name, Dir.tmpdir, mode: IO::RDWR) do |stream|
        run.copy_to_in_schema(sql: plan_h[:interpolated_sql], writeable_io: stream).tap do
          stream.rewind
          s3_file.upload(stream)
        end
      end
    end
  end

  # Redshift-specific version of CopyToRunner
  module UnloadRunner

    UNLOAD_TEMPLATE = "UNLOAD (\n%s\n) TO %s\n%s".freeze

    extend self

    def run(run:, plan_h:)
      raise "UnloadRunner only works in Redshift." unless run.use_redshift?

      s3_full_path = S3File.create(
        'export',
        s3_region_name: plan_h[:s3_region_name],
        s3_bucket_name: plan_h[:s3_bucket_name],
        s3_file_path: plan_h[:s3_file_path],
        s3_file_name: plan_h[:s3_file_name],
        run: run
      ).to_s

      sql = UNLOAD_TEMPLATE % [
        RedshiftConnection.connection.quote(plan_h[:interpolated_sql]),
        RedshiftConnection.connection.quote(s3_full_path),
        plan_h[:redshift_unload_options]
      ]
      run.execute_in_schema(sql)
    end
  end

  # Runs TransformValidations; internal-only Runner
  module ValidationRunner

    extend self

    def run(run:, transform_validation_h:)
      transform_validation_sql = transform_validation_h[:interpolated_sql]
      if ids = run.select_values_in_schema(transform_validation_sql).presence
        {
          failed_validation_name: transform_validation_h[:interpolated_name],
          failed_validation_sql: transform_validation_sql,
          ids_failing_validation: ids.join(', ')
        }
      end
    end
  end

  # Runs WorkflowDataQualityReports; internal-only Runner
  module WorkflowDataQualityReportRunner

    extend self

    def run(run:, plan_h:)
      result = run.select_all_in_schema(plan_h[:interpolated_sql])
      [result.columns] + result.rows
    end
  end

end
