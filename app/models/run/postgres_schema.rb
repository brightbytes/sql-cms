# frozen_string_literal: true
# This is a simple wrapper for some of the apartment gem's postgres schema manipulation methods.  It exists because I'd eventually like to replace apartment with
#  something that I don't have to monkey-patch (see the initializer) and doesn't break `annotate -ik` (by no longer annotating indexes and FKs) such that I have to
#  come up with an ugly hack-around.
module Run::PostgresSchema

  extend ActiveSupport::Concern

  def schema_exists?
    self.class.list_schemas.include?(schema_name)
  end

  def create_schema
    unless schema_exists?
      with_connection_reset_on_error do
        # Putting this inside a transaction prevents the connection from being hosed by SQL error
        transaction { Apartment::Tenant.create(schema_name) }
      end
    end
    nil
  end

  def drop_schema
    if schema_exists?
      with_connection_reset_on_error do
        # Putting this inside a transaction prevents the connection from being hosed by SQL error
        transaction { Apartment::Tenant.drop(schema_name) }
      end
    end
    nil
  end

  def execute_in_schema(sql)
    create_schema # no-op if it already exists

    with_connection_reset_on_error do
      in_schema_context { Apartment.connection.execute(sql) }
    end
  end

  # The guts of the following 2 methods were cribbed from https://github.com/diogob/postgres-copy/blob/master/lib/postgres-copy/acts_as_copy_target.rb

  # Also, if you're the sort who loves reading about lowest-level methods available on a .raw_connection for Postgres, see http://deveiate.org/code/pg/PG/Connection.html

  def copy_from_in_schema(sql:, enumerable:)
    with_connection_reset_on_error do
      in_schema_context do
        Apartment.connection.raw_connection.copy_data(sql) do
          enumerable.each do |line|
            Apartment.connection.raw_connection.put_copy_data(line) unless line.blank?
          end
        end
      end
    end
  end

  # A streaming COPY per-table would be the best way to get data out, by which I mean something like this from the CL:
  #   psql <fin_pipeline_connection> -c "\COPY source_pipeline_table TO STDOUT ..." | psql <fin_app_db_connection> -c "\COPY target_fin_app_table FROM STDIN ..."
  # Short of that, this will have to do.
  def copy_to_in_schema(sql:, writeable_io:)
    with_connection_reset_on_error do
      in_schema_context do
        Apartment.connection.raw_connection.copy_data(sql) do
          while line = Apartment.connection.raw_connection.get_copy_data
            writeable_io.puts(line)
          end
        end
      end
    end
  end

  def eval_in_schema(rails_migration)
    create_schema # no-op if it already exists

    with_connection_reset_on_error do
      in_schema_context do
        Apartment.connection.instance_eval(rails_migration)
      end
    end
  end

  # These next 5 are useful in tests and for debugging failed Runs (in addition to some of them being used by the system)

  def select_all_in_schema(sql)
    raise "Schema #{schema_name} doesn't exist." unless schema_exists?

    with_connection_reset_on_error do
      in_schema_context { Apartment.connection.select_all(sql) }
    end
  end

  def select_rows_in_schema(sql)
    raise "Schema #{schema_name} doesn't exist." unless schema_exists?

    with_connection_reset_on_error do
      in_schema_context { Apartment.connection.select_rows(sql) }
    end
  end

  def select_one_in_schema(sql)
    raise "Schema #{schema_name} doesn't exist." unless schema_exists?

    with_connection_reset_on_error do
      in_schema_context { Apartment.connection.select_one(sql) }
    end
  end

  def select_values_in_schema(sql)
    raise "Schema #{schema_name} doesn't exist." unless schema_exists?

    with_connection_reset_on_error do
      in_schema_context { Apartment.connection.select_values(sql) }
    end
  end

  def select_value_in_schema(sql)
    raise "Schema #{schema_name} doesn't exist." unless schema_exists?

    with_connection_reset_on_error do
      in_schema_context { Apartment.connection.select_value(sql) }
    end
  end

  private

  def in_schema_context
    Apartment::Tenant.switch(schema_name.presence) do # nil => public
      # Putting this inside a transaction prevents the connection from being hosed by SQL error
      transaction { yield }
    end
  end

  def with_connection_reset_on_error
    yield
  rescue
    reset_connection!
    raise
  end

  # The Rails postgres adaptor's connection becomes unusable after ANY error, hence it needs to be reset.  FML.
  def reset_connection!
    Apartment::Tenant.reset
  end

  module ClassMethods

    LIST_SCHEMAS_SQL = "SELECT nspname FROM pg_catalog.pg_namespace"

    def list_schemas
      Apartment.connection.select_values(LIST_SCHEMAS_SQL)
    end

  end

end
