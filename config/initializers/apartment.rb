# frozen_string_literal: true
require 'apartment/adapters/abstract_adapter'
require 'apartment/adapters/postgresql_adapter'

# Patch b/c we only need a small subset of what this gem does:
Apartment::Adapters::PostgresqlSchemaFromSqlAdapter.class_eval %q{
  # We don't want this at all; instead, we'll execute the DDL transforms in the correct schema
  def import_database_schema
    # clone_pg_schema
    # copy_schema_migrations
  end
}

Apartment.configure do |config|
  config.excluded_models =
    %w(
      User
      PaperTrail::Version
      Customer
      Workflow
      WorkflowDependency
      Notification
      Transform
      TransformDependency
      Validation
      TransformValidation
      DataQualityReport
      WorkflowDataQualityReport
      Run
      RunStepLog
      )
  config.use_sql = true
  config.persistent_schemas = ['shared_extensions']
end
