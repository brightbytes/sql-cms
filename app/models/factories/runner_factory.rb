# frozen_string_literal: true
# Produces runner modules that execute the supplied plan hash.
module RunnerFactory

  extend self

  RUNNERS_FOR_SELECT = [
    [' SQL', 'Sql'],
    [' COPY ... FROM', 'CopyFrom'],
    [' Postgres COPY ... TO', 'CopyTo'],
    [' Redshift UNLOAD', 'Unload'],
    [' Rails Migration', 'RailsMigration'],
    [' Auto-load', 'AutoLoad'],
  ]

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
        s3_file_name: plan_h[:interpolated_s3_file_name]
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
          sql = "COPY #{table_name} (#{header_s}) FROM STDIN WITH CSV HEADER"

          # Ruby 2.6 appears to have changed the implementation of CSV to chomp-through more of the file than just the header.
          # So, just in case, we rewind the stream
          stream.rewind
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
      run.eval_in_schema(plan_h[:interpolated_sql])
    end
  end

  # Imports a table from a data file
  module CopyFromRunner

    POSTGRES_COPY_FROM_TEMPLATE = "COPY\n%s\n FROM STDIN\n%s"

    REDSHIFT_COPY_FROM_TEMPLATE = "COPY\n%s\n FROM %s\n%s"

    extend self

    def run(run:, plan_h:)
      s3_file = S3File.create(
        'import',
        s3_region_name: plan_h[:s3_region_name],
        s3_bucket_name: plan_h[:s3_bucket_name],
        s3_file_path: plan_h[:s3_file_path],
        s3_file_name: plan_h[:interpolated_s3_file_name]
      )

      target_expression = plan_h[:params]&.fetch(:table_name, nil)&.to_s
      column_list = plan_h[:params]&.fetch(:column_list, nil)&.to_s
      target_expression += " #{column_list}" if column_list

      if run.use_redshift?
        s3_full_path = s3_file.to_s
        sql = REDSHIFT_COPY_FROM_TEMPLATE % [
          target_expression,
          RedshiftConnection.connection.quote(s3_full_path),
          plan_h[:import_transform_options]
        ]
        run.execute_in_schema(sql)
      else
        url = s3_file.s3_presigned_url
        raise "Unable to locate #{s3_file}!" unless url
        sql = POSTGRES_COPY_FROM_TEMPLATE % [
          target_expression,
          plan_h[:import_transform_options]
        ]
        open(url) { |stream| run.copy_from_in_schema(sql: sql, enumerable: stream) }
      end
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

    COPY_TO_TEMPLATE = "COPY (\n%s\n) TO STDOUT\n%s"

    extend self

    def run(run:, plan_h:)
      raise "CopyToRunner doesn't work in Redshift." if run.use_redshift?

      s3_file = S3File.create(
        'export',
        s3_region_name: plan_h[:s3_region_name],
        s3_bucket_name: plan_h[:s3_bucket_name],
        s3_file_path: plan_h[:s3_file_path],
        s3_file_name: plan_h[:interpolated_s3_file_name],
        run: run
      )

      sql = COPY_TO_TEMPLATE % [
        plan_h[:interpolated_sql],
        plan_h[:export_transform_options]
      ]

      # Tragically, we can't use IO.pipe b/c AWS needs to know the file size in advance so as to chunk the data when appropriate
      Tempfile.open(s3_file.s3_file_name.split('/').last, Dir.tmpdir, mode: IO::RDWR) do |stream|
        run.copy_to_in_schema(sql: sql, writeable_io: stream).tap do
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
        s3_file_name: plan_h[:interpolated_s3_file_name],
        run: run
      ).to_s

      sql = UNLOAD_TEMPLATE % [
        RedshiftConnection.connection.quote(plan_h[:interpolated_sql]),
        RedshiftConnection.connection.quote(s3_full_path),
        plan_h[:export_transform_options]
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
