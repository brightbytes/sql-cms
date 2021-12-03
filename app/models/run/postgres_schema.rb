# frozen_string_literal: true
# This is a simple Run mixin for manipulating postgres/redshift schemas.
# FIXME - PORT TO FIRST-ORDER OBJECT, RATHER THAN HAVING AS A CONCERN. THAT WILL INVOLVE REFACTORING use_redshift? HACK
module Run::PostgresSchema

  extend ActiveSupport::Concern

  def schema_exists?
    self.class.list_schemata(use_redshift?).include?(schema_name)
  end

  def create_schema
    unless schema_exists?
      self.class.in_db_context(use_redshift?) do
        escaped_schema = ActiveRecord::Base.connection.quote_string(schema_name)
        # Putting this inside a transaction prevents the connection from being hosed by SQL error
        transaction { connection.execute("CREATE SCHEMA #{escaped_schema}") }
      end
    end
  end

  def drop_schema
    if schema_exists?
      self.class.in_db_context(use_redshift?) do
        escaped_schema = ActiveRecord::Base.connection.quote_string(schema_name)
        # Putting this inside a transaction prevents the connection from being hosed by SQL error
        transaction { connection.execute("DROP SCHEMA #{escaped_schema} CASCADE") }
      end
    end
  end

  def execute_in_schema(sql)
    self.class.in_db_context(use_redshift?) do
      in_schema_context { connection.execute(sql) }
    end
  end

  # The guts of the following 2 methods were cribbed from https://github.com/diogob/postgres-copy/blob/master/lib/postgres-copy/acts_as_copy_target.rb

  # Also, if you're the sort who loves reading about lowest-level methods available on a .raw_connection for Postgres, see http://deveiate.org/code/pg/PG/Connection.html

  def copy_from_in_schema(sql:, enumerable:)
    raise "This method is not available for use in Redshift." if use_redshift?

    self.class.in_db_context(false) do
      in_schema_context do
        connection.raw_connection.copy_data(sql) do
          enumerable.each do |line|
            connection.raw_connection.put_copy_data(line) unless line.blank?
          end
        end
      end
    end
  end

  # A streaming COPY per-table would be the best way to get data out, by which I mean something like this from the CL:
  #   psql <fin_pipeline_connection> -c "\COPY source_pipeline_table TO STDOUT ..." | psql <fin_app_db_connection> -c "\COPY target_fin_app_table FROM STDIN ..."
  # Short of that, this will have to do.
  def copy_to_in_schema(sql:, writeable_io:)
    raise "This method is not available for use in Redshift." if use_redshift?

    self.class.in_db_context(false) do
      in_schema_context do
        connection.raw_connection.copy_data(sql) do
          while line = connection.raw_connection.get_copy_data
            writeable_io.puts(line)
          end
        end
      end
    end
  end

  # FIXME - THIS DOES NOT WORK WITH THE REDSHIFT ADAPTER BECAUSE ANY `create_table` STATEMENT PRODUCES THE ERROR `wrong number of arguments (given 3, expected 2)`
  #         (OTHER STATEMENTS WORK FINE.)  THIS IS UNDOUBTEDLY A BUG IN THE REDSHIFT GEM, THOUGH I HAVEN'T VERIFIED BY ATTEMPTING TO WRITE MIGRATIONS INDEPENDENTLY.
  def eval_in_schema(rails_migration)
    self.class.in_db_context(use_redshift?) do
      in_schema_context { connection.instance_eval(rails_migration) }
    end
  end

  # These next 5 are useful in tests and for debugging failed Runs (in addition to some of them being used by the system)

  def select_all_in_schema(sql)
    self.class.in_db_context(use_redshift?) do
      in_schema_context { connection.select_all(sql) }
    end
  end

  def select_rows_in_schema(sql)
    self.class.in_db_context(use_redshift?) do
      in_schema_context { connection.select_rows(sql) }
    end
  end

  def select_one_in_schema(sql)
    self.class.in_db_context(use_redshift?) do
      in_schema_context { connection.select_one(sql) }
    end
  end

  def select_values_in_schema(sql)
    self.class.in_db_context(use_redshift?) do
      in_schema_context { connection.select_values(sql) }
    end
  end

  def select_value_in_schema(sql)
    self.class.in_db_context(use_redshift?) do
      in_schema_context { connection.select_value(sql) }
    end
  end

  private

  # I still need this in 2018?  Really??!
  def connection
    self.class.connection
  end

  def set_search_path!(search_path_schema)
    connection.execute(ActiveRecord::Base.send(:sanitize_sql_array, ["SET search_path TO ?", search_path_schema]))
  end

  def in_schema_context
    raise "This Run lacks a schema_name!" unless schema_name.present?
    set_search_path!(schema_name)
    yield
  ensure
    set_search_path!('public')
  end

  module ClassMethods

    LIST_SCHEMATA_SQL = "SELECT nspname FROM pg_catalog.pg_namespace"

    def list_schemata(use_redshift = false)
      in_db_context(use_redshift) do
        connection.select_values(LIST_SCHEMATA_SQL)
      end
    end

    def in_db_context(use_redshift = false)
      # Sadly, establish_connection isn't threadsafe in sidekiq. I tried creating a pool on-the-fly too in a branch.  No dice.
      # The only viable solution at this time is to run all redshift queries serially, which is accomplished by having 1 sidekiq thread
      #  per Heroku dyno.  Another alternative would be to revert to Delayed::Job, but I'd rather not deal.
      if use_redshift
        begin
          establish_connection(:redshift)
          yield
        ensure
          establish_connection(Rails.env.to_sym)
        end
      else
        yield
      end
    end

  end

end
