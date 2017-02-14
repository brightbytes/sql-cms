# dpl-cms

This is a general-purpose application for creating per-Customer Workflows of interdependent SQL Transforms that convert a set of Import DataFiles on S3 to a set of Export DataFiles on S3.

A Workflow may be Run multiple times, and each time the system will deposit its Export DataFiles in a namespaced S3 "directory". Every Run occurs within a newly-created Postgres (or Redshift) schema.

The following entities exist in the public Postgres (or Redshift) schema:

- User: You, the SQL Analyst

- Customer: The Customer with which every Workflow and DataFile must be associated

- DataFile: Comes in 2 varieties:

  - Import DataFile: A specification of the location of a tabular flat-file that already exists on S3 (e.g. a CSV file)

  - Export DataFile: A specification of the desired location to which the system will write a tabular flat-file on S3 (e.g. a CSV file)

- Workflow: A named, per-Customer collection of the following, each described in detail below:

  - Various types of SQL Transform and their TransformDependencies, TransformValidations, and (for some types of Transform) DataFiles

  - DataQualityReports

  - Notifications

  - Runs and their RunStepLogs

- Notification: An association of a Workflow with a User for the purpose of notifying the User whenenever a Run of that Workflow successfully or unsuccessfully completes.

- Transform: A named, optionally-parametrized SQL query that may be optionally associated with an Import or Export DataFile and that specifies one of the following Runners for the SQL:

  - RailsMigrationRunner: Evals the contents of the sql field as a Ruby Migration (because hand-writing boilerplate DDL sucks); supports every feature that Rails Migrations support

  - CopyFromRunner: Requires association with an Import DataFile, and requires that its sql field be a `COPY ... FROM ...` type of SQL statement

  - SqlRunner: Allows its sql field to be any type of DDL statement (CREATE) or DML statement (INSERT, UPDATE, DELETE, but not SELECT, since that would be pointless) other than those that read from or write to files.

  - CopyToRunner: Requires association with an Export DataFile, and requires that its sql field be a `COPY ... TO ...` type of SQL statement

  - AutoLoadRunner: **Not yet implemented** - Will require only an association to an Import DataFile, and will introspect on the DataFile's header, create a table with string columns based upon the sql-identifier-coerced version of the headers, and load the table from the file.

  - UnloadRunner: **Not yet implemented** -  Will be a Redshift-specific version of CopyToRunner

- TransformDependency: An association of one Transform with another where the Prerequisite Transform must be run before the Postrequisite Transform.  Every Workflow has a TransformDependency-based DAG that is resolved at runtime into a list of groups of Transforms, where each Transform in a group may be run in parallel

- TransformValidation: An association of a Transform to a parameterized Validation that specifies the parameters required for the Validation.  When a TransformValidation fails, that Transform is considered to have failed, and execution halts in failure after that Transform's group completes.

- Validation: A named, reusable, manditorily-parametrized SQL query that validates the result of a Transform, e.g. to verify that all rows in a table have a value for a given column, are unique, reference values in another table, etc.  Similar in intent to Rails Validations.  Upon failure, returns the IDs of all invlalid rows.

- DataQualityReport: A named, optionally-parametrized SELECT SQL statement that is run after all Transforms have completed.  The system will store the tabular data returned by the SQL as well as include that data in the Notification email that is sent after a successful Run.

- Run: A record of the postgres-schema_name, current status, and execution_plan of a given Run of a Workflow.  When a User creates a Run for a Workflow, the system serializes the Workflow and *all* its dependent objects into the execution_plan field, and execution of the Run proceeds against that field.  This allows a Workflow to be changed at any time without affecting any current Runs.

- RunStepLog: A per-Run record of the execution of a single Transform or DataQualityReport that in success cases stores the result of running the SQL and in failure cases either stores TransformValidation failures or - in the case of an Exception being raised - the error message
