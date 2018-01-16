# sql-cms

## What is it?

sql-cms is a standalone application that stores and runs Workflows comprised of SQL-based Transforms, Transform Validations, and Data Quality Reports.

When run, a Workflow creates a new Postgres/Redshift schema for the Run, and in that schema may execute DDL, load data files from S3, transform the loaded data via DML, validate the transformed data using SQL, and export new data files back out to S3.

For later examination, the system tracks the result of every step of the Run - be that result a count of affected rows, a Validation failure, or an Exception - as a RunStepLog.  Furthermore, the app uses, retains, and dumps to S3 the complete immutable JSON Execution Plan for each Run, again for later examination.

## So what?

The organization of SQL expressions in a Workflow CMS that at runtime namespaces its operations in Postgres/Redshift schemas and under S3 prefixes named for the Run confers the following benefits:

- A given Workflow may be associated with multiple Customers, each having their own source S3 data files, and that data will proceed through identical processing steps at runtime.

- The user-specified dependency DAG of Transforms within a Workflow allows the app to execute in parallel all sibling Transforms (in the leaf-to-parent direction) and all Data Quality Reports.

- Similarly, Workflows themselves may also depend upon other Workflows, with the DAG thus defined also permitting the application to execute Transforms and Data Quality Reports in parallel. Furthermore, due to their composability, a given Workflow's Transforms and Data Quality Reports may be reused/rerun as a unit by any number of other Workflows.

- Because it is stored in the context of a Postgres/Redshift schema, the data produced by a given Workflow Run may be referenced by any other Workflow Run.  This is particularly useful when source S3 data files are huge. In such cases, one may create a Workflow that loads the data, Run it once, and then create separate Workflows that Transform and Report on the loaded data by referencing schema-prefixed table names.

- Another advantage of Postgres/Redshift schemas is that they serve as a context for examining data and debugging Workflow SQL after a Run, simply by setting the Postgres/Redshift SEARCH_PATH to the schema for the Run.

- An end-User of this application need have no programming knowledge whatsoever: only a basic knowledge of SQL and minimal acquaintence with ETL is required.

## Now what?

To begin exploration of the application on your local machine, see [Local Project Setup](#project_setup) below, and try to get the [Demo Workflow](#demo_workflow) running.



## sql-cms concepts and entities

All application entities exist in the **public** Postgres schema.  The following notes concern the intended purposes of the application entities:

- **Workflow**

- **WorkflowConfiguration**: Stores the S3 working directory and an optional Customer association; it `has_many`:

  - Notifications

  - Runs and their RunStepLogs

- **Notification**: An association of a Workflow with a User for the purpose of notifying the User whenenever a Run of that Workflow successfully or unsuccessfully completes.

- **Transform**: A named, optionally-parametrized SQL query, some types of which must be associated with an S3 file, and that specifies one of the following Runners for the SQL:

  - **RailsMigrationRunner**: Evals the contents of the sql field as a Ruby Migration (because hand-writing boilerplate DDL sucks); supports every feature that Rails Migrations support.  If preferred, SQL Analysts uncomfortable with Ruby code may use the generic **SqlRunner** described below to author DDL ... though I'd recommend learning Rails Migration syntax, because it's much more convenient.

  - **CopyFromRunner**: Requires specification a file to be imported from S3, and requires that its sql field be a `COPY ... FROM STDIN ...` type of SQL statement

  - **SqlRunner**: Allows its sql field to be any type of DDL statement (CREATE) or DML statement (INSERT, UPDATE, DELETE, but not SELECT, since that would be pointless) other than those that read from or write to S3 files (COPY).

  - **CopyToRunner**: Requires specification of an s3 file location to which to export data, and requires that its sql field be a `COPY ... TO STDOUT ...` type of SQL statement

  - **AutoLoadRunner**: Requires only the specification of a file to be imported from S3 and a :table_name param, and introspects on the file's header, creates a table with string columns based upon the sql-identifier-coerced version of the headers, and loads the table from the file.  Accepts a :name_type_map param to create the indicated columns as the indicated types, e.g. { params: { name_type_map: { my_column: :integer } } }.  Also accepts an :indexed_columns param with an array of columns to index.  At this time, additional features are deliberately not supported: if a more-complex scenario is required, define a `RailsMigrationRunner` transform and a `CopyFromRunner` transform.

- **TransformDependency**: An association of one Transform with another where the Prerequisite Transform must be run before the Postrequisite Transform.  Every Workflow has a TransformDependency-based DAG that is resolved at Run-time into a list of groups of Transforms, where each Transform in a given group may be run in parallel with all other Transforms in that group.

- **TransformValidation**: An association of a Transform to a parameterized Validation that specifies the parameters required for the Validation.  When a TransformValidation fails, the system fails its associated Transform, and execution halts in failure after that Transform's group completes execution.

- **Validation**: A named, reusable, manditorily-parametrized SQL SELECT statement that validates the result of a Transform via an intermediating TransformValidation's params, e.g. to verify that all rows in a table have a value for a given column, are unique, reference values in another table, etc.  Similar in intent to Rails Validations.  Upon failure, returns the IDs of all invalid rows.

- **DataQualityReport**: A named, reusable, manditorily-parametrized SQL SELECT statement the system runs via an intermediating WorkflowDataQualityReport's params after all Transforms have completed.  The system will store the tabular Report data returned by the SQL, and also include that data in a Notification email that is sent after a successful Run.

- **Run**: A record of the postgres-schema_name (useful for debugging/examining data), current status, and execution_plan of a given Run of a Workflow.  When a User creates a Run for a Workflow, the system serializes the Workflow and **all** its dependent objects into the Run#execution_plan field, and execution of the Run proceeds against that field.  This allows a Workflow to be changed at any time without affecting any current Runs.

- **RunStepLog**: A per-Run record of the execution of a single Transform or DataQualityReport that in success cases stores the result of running the SQL, in failure cases stores TransformValidation failures, or - when the Step raises an Exception - the error details.


- params
- sql snippets
- more atomic, less deadlocking

- dump repo: in rake tasks section

## Run Management

This application uses Sidekiq via Active::Job for parallelization of Runs, Transforms, and DataQualityReports.

To monitor Sidekiq locally or once deployed, click on Admin | Sidekiq in the application.

## <a name="demo_workflow">Demo Workflow</a>

This application comes with a rather pathetic Demo Workflow that was ported from an ancestral app.

In that application too, it was a pre-requirement-specification Demo Workflow intended to be sufficiently complex for basic validation and testing.

In and of itself, it's meaningless, but it does provide a few limited examples of how to use this system, and is itself also used by the test suite.

Furthermore, after seeding into a production application, it may be used to quickly validate that the application is working.  For that purpose, a rake task is provided for uploading the demo files to s3; its usage is as follows:

```
# For this to succeed, the AWS Commandline tools must be installed locally
rake demo:upload_to_s3['s3://bucket/path/to/files/']
```

Note that the WorkflowConfiguration for the Demo Workflow will need to be configured with the corresponding s3_bucket_name and s3_file_path.

## Heroku Deployment

There are 5 rake tasks in `lib/tasks/heroku.rake` for managing a Heroku deployment:

```
# Turn on Heroku maint mode
heroku:maint:on

# Turn off Heroku maint mode
heroku:maint:off

# Deploy to Herou using the eponymous .git/config repo
heroku:deploy

# Download the production DB locally
heroku:download

# Upload a downloaded production DB into the Dev ENV
heroku:upload:development
```

To deploy to Heroku, you'll need 3 Heroku AddOns: Postgres, Redis (for Sidekiq), and SendGrid.

You'll only need one 1x Sidekiq Worker dyno if all Workflows will be run on Postgres.  However, to also run Workflows on Redshift, you'll need a 2nd Worker Heroku Resource pool of circa four 1x Sidekiq Worker dynos

You'll want to configure many - though not all - of the same environment variables on Heroku as you do for your local setup. I set the following on my Herkou app:

```
# These are required
AWS_ACCESS_KEY_ID=
AWS_SECRET_ACCESS_KEY=

# These are optional
DEFAULT_S3_BUCKET=
DEFAULT_S3_REGION=

# Rails requires these
DEVISE_SECRET_KEY=
SECRET_KEY_BASE=

# Heroku recommends these
ERROR_PAGE_URL=
MAINTENANCE_PAGE_URL=

# Required for User Auth and the Notification email
MAIL_SENDER='no-reply@somewhere.com'

# App URL
PRODUCTION_HOST=

# Just set these
RACK_ENV=production
RAILS_ENV=production

# Not sure if these came automatically or if I set them
RAILS_LOG_TO_STDOUT=enabled
RAILS_SERVE_STATIC_FILES=enabled

# I've been setting these forever; not sure they're actually required anymore
LANG='en_US.UTF-8'
TZ='US/Pacific'

# Only set these if you need to run Workflows on Redshift
REDSHIFT_HOST=
REDSHIFT_PORT=
REDSHIFT_USER=
REDSHIFT_PASSWORD=
REDSHIFT_DATABASE=
```

Note that the above excludes ENV vars set up by the 3 Heroku AddOns.

## Running Workflows on Redshift

Configuring the application to run on Redshift requires the following steps:

1) Set the 5 Redshift-related environment variables.  (Coming soon a future release, all these but the password will be encapsulated by an entity manipulable in the application, though the password will still need to be set by an environment variable.)

2) Enable the `worker_redshift` Heroku Worker Resource that is defined in this application's `Procfile`, and set the number of 1X dynos to the level of parallelism desired.  (Mine is currently set to 4.)

Configuring a Workflow to run on Redshift requires the following steps:

1) Create a WorkflowConfiguration with the `Redshift?` attribute flagged.

2) If importing from and/or exporting to S3, in the same WorkflowConfiguration be sure to set at least the appropriate `CREDENTIALS 'aws_iam_role=arn:aws:iam::...'` in the Import Transform Options and/or Export Transform Options fields.

## [Environment Setup for local development](https://github.com/brightbytes/sql-cms/wiki/Local-Dev-Env-Setup)

## <a name="project_setup">Local Project Setup</a>

1) Add environment variables

  * Create a .env file in your sql-cms project folder with the following contents; it will be automatically used by the `dotenv` gem:

    ```
    PORT=3000
    RACK_ENV=development
    LANG='en_US.UTF-8'
    TZ='US/Pacific' # Or whatever

    DEFAULT_S3_REGION='us-west-2'
    DEFAULT_S3_BUCKET=<your preferred default bucket here>

    MAIL_SENDER='no-reply@somewhere.com'

    # Only set this if you deploy somewhere
    PRODUCTION_HOST='your-app-name.herokuapp.com'

    # Only set this if you want to store a large quantity of seed data as a binary image (in a separate repository, of course)
    SEED_DATA_DUMP_REPO='/path/to/seed/data/dump/repo'

    # You must supply these. (Most folks already have these set up globally in their env.)
    AWS_ACCESS_KEY_ID=<your access ID here>
    AWS_SECRET_ACCESS_KEY=<your secret access key here>

    # Only set these if you need to run Workflows on Redshift
    REDSHIFT_HOST=
    REDSHIFT_PORT=
    REDSHIFT_USER=
    REDSHIFT_PASSWORD=
    REDSHIFT_DATABASE=
    ```

2) Reset your environment and load Postgres with the Demo Workflow

  * This is useful for ongoing dev when if ever you hose your environment, and is also useful when rapidly iterating on a new migration in a branch:

  ```
  rake one_ring
  ```

  Run the above script every time you want to re-initialize your dev environment to baseline.

  * IMPORTANT: **ONLY** if this is the very first time you are creating this app on your machine, you must first separately-invoke db:create to avoid the new production-DB check of Rails 5:

  ```
  rake db:create
  rake one_ring
  ```

  Thereafter, `rake one_ring` will suffice.

3) Start your web server and worker:

  * In order to run the application in development environment you need both a web server and a sidekiq worker.

  * I recommend using 2 separate processes rather than something like `foreman` because both `thin` and `sidekiq` provide more-useful console logging, and I've also had `foreman start` wedge my machine to the point that it could only be fixed by a reboot:

  ```
  # Start thin in one terminal tab:
  rails s
  ```

  ```
  # Start sidekiq in another terminal tab
  sidekiq
  ```

## FAQ (that I ask of myself, to be clear)

Q: Why isn't this repo a gem?

A: It is quicker for me to make changes and deploy them by keeping this as an application for now. That is, I need to use and change this application relatively frequently, and I'd rather not deal with the extra steps of releasing a new version of a gem and updating the app to us it for every change I make. However, there is probably tooling that would automate CD of this repo as a gem: once I have a chance to figure it out, this repo will become a gem.

Q: What new features does this app need?

A: [Future plans](https://github.com/brightbytes/sql-cms/wiki/Future-Plans)
