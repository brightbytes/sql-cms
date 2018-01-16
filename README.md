# sql-cms

## What is it?

sql-cms is a standalone application that stores and runs Workflows comprised of SQL-based Transforms, Transform Validations, and Data Quality Reports.

When run, a Workflow creates a new Postgres/Redshift schema for the Run, and in that schema may execute DDL, load data files from S3, transform the loaded data via DML, validate the transformed data using SQL, and export new data files back out to S3.

For later examination, the system tracks the result of every step of the Run - be that result a count of affected rows, a Validation failure, or an Exception - as a RunStepLog.  Furthermore, the app uses, retains, and dumps to S3 the immutable JSON Execution Plan for each Run, again for later examination.

## So what?

The organization of SQL statements in a Workflow CMS that at runtime namespaces its operations in Postgres/Redshift schemas and its exported results under S3 prefixes named for the Run confers the following benefits:

- A given Workflow may be associated with multiple Customers, each having their own source S3 data files, and all Customers' data will proceed through identical processing steps at runtime.

- The user-specified dependency DAG of Transforms within a Workflow allows the app to execute in parallel all sibling Transforms (in the leaf-to-parent direction), and all Data Quality Reports.

- Similarly, Workflows themselves may also depend upon other Workflows, with the DAG thus defined also permitting the application to execute Transforms and Data Quality Reports in parallel. Furthermore, due to their composability, a given Workflow's Transforms and Data Quality Reports may be reused/rerun as a unit by any number of other Workflows.

- Because it is stored in the context of a Postgres/Redshift schema, the DB data produced by a given Workflow Run may be referenced by any other Workflow Run in the same DBMS.  This is particularly useful when source S3 data files are huge. In such cases, one may create a Workflow that loads the data, Run it once, and then create separate Workflows that Transform and Report on the loaded data by referencing its schema-prefixed table names.

- Another advantage of Postgres/Redshift schemas is that they serve as a context for examining data and debugging Workflow SQL failures after a Run, simply by setting the Postgres/Redshift SEARCH_PATH to the schema for the Run.

- An end-User of this application need have no programming knowledge whatsoever: only a basic knowledge of SQL and minimal acquaintence with ETL is required.

## Now what?

To begin exploration of the application on your local machine, see [Local Project Setup](#project_setup) below, and get the [Demo Workflow](#demo_workflow) running.

Or, skim the following sections for a preview of the central application concepts, and use cases for the application.

## Entities and Concepts

All sql-cms entities exist in the **public** Postgres schema.  Whereas, all entities produced by Runs exist in Postgres or Redshift schemas named after the Workflow and (optionally) Customer for the Run.

Workflows, Transforms, TransformValidations, and WorkflowDataQualityReports all have a 'Params YML' field that may be used to specify parameters that the system will interpolate into their associated SQL queries.  Workflow params may be overridden by Transform params and WorkflowDataQualityReport params, and Transform params may be overridden by TransformValidation params.  With the sole exception of the [AutoLoadRunner](#auto_load_runner), the expected format for all params is as a YML hash, e.g.:

```
table_name: table_name_goes_here
column_name: column_name_goes_here
```

Parameterization allows Validations and DataQualityReports to be easily reused by multiple Transforms and Workflows, respectively. It also allows SQL Snippets with parameter references to be reused in multiple Transforms.  And, it allows param defaults to be specified at the Workflow level.

The following notes concern the intended purposes of the high-level application entities:

- **Workflow**: A Workflow may comprise Transforms and their associated Validations, and Data Quality Reports.  A Workflow may also include other Workflows to be run as a prerequisite.

- **WorkflowConfiguration**: A WorkflowConfiguration must be defined and associated with a Workflow - and optionally associated with a Customer - for the system to create and execute Runs.  For Workflows that import from and/or export to S3, the WorkflowConfiguration must define an S3 region, bucket, and (optionally) file path, as well as defining import Transform options for the Workflow's Postgres/Redshift CopyFrom Transforms and export Transform options for Workflow's Postgres CopyTo Transforms or Redshift Unload Transforms. A WorkflowConfiguration may optionally specify Users to notify by email upon success or failure of a Run.

- **Transform**: A named, optionally-parametrized SQL query - some types of which must be associated with an S3 file instead of SQL - that specifies the prerequisite Transforms it depends upon and utilizes one of the following Runners for the SQL:

  - **RailsMigrationRunner**: Evals the contents of the sql field as a Ruby Migration (because hand-writing boilerplate DDL is a hassle); supports every feature that Rails Migrations support.  If preferred, those uncomfortable with Ruby code may use the generic **SqlRunner** described below to author DDL.  Sadly, for reasons unclear this runner does not currently work with the Rails 5 Redshift gem.

  - **CopyFromRunner**: Requires specification a file to be imported from S3.  Its Import Transform Options may be specified in the WorkflowConfiguration.  Works for both Postgres and Redshift, the latter of which requires at least the specification of `CREDENTIALS` in the Import Transform Options.

  - **SqlRunner**: Allows its sql field to be any type of DDL or DML statement other than those that read from or write to S3 files.  Multiple SQL statements may appear in this field if each statement is terminated with a semicolon.  However, one should avoid multiple DML statements appearing in the same Transform for the following reasons:

    - It prevents the parallelism that could be achieved by defining a chain of prerequisite Transforms.

    - If multiple Transforms contain multiple statements that concern the same tables, it becomes more likely that two or more of them will deadlock.

  - **CopyToRunner**: Requires specification of a base s3 prefix in the WorkflowConfiguration to which to export data, after which will appear an infix named after the Run, and finally the file name specified by the Transform.  Works only for Postgres.

  - **UnloadRunner**: Requires specification of a base s3 prefix in the WorkflowConfiguration to which to export data, after which will appear an infix named after the Run, and finally the file name specified by the Transform.  Works only for Redshift, which requires at least the specification of `CREDENTIALS` in the Import Transform Options.

  - <a name="auto_load_runner">**AutoLoadRunner**</a>: Requires only the specification of a file to be imported from S3 and a :table_name param. It introspects on the file's header, creates a table with string columns based upon the sql-identifier-coerced version of the headers, and loads the table from the file.  Accepts a :name_type_map param to create the indicated columns as the indicated types.  Also accepts an :indexed_columns param with an array of columns to index.  At this time, additional features are deliberately not supported because they are not required: this Runner exists to demonstrate what could be possible, if ever needed.

- **Validation**: A named, reusable SQL SELECT statement that validates the result of a Transform using an intermediating TransformValidation's params (if any), e.g. to verify that all rows in a table have a value for a given column, are unique, reference values in another table, etc.  Similar in intent to Rails Validations.  Upon failure, returns the IDs of all invalid rows, for later manual inspection in the schema, if needed. Note that the SQL SELECT statement must be written so as to return the ids of rows that violate the Validation. When associated with a Transform, a failure will cause execution to halt after that Transform's group of dependency siblings completes execution.

- **DataQualityReport**: A named, reusable SQL SELECT statement the system runs using an intermediating WorkflowDataQualityReport's params (if any) after all Transforms have completed.  The system will store the tabular Report data returned by the SQL, and also include that data in any Notification email(s) sent after a successful Run.

- **Run**: A record of the postgres-schema_name (useful for debugging/examining data), current status, and execution_plan of a given Run of a Workflow.  When a User creates a Run for a WorkflowConfiguration, the system serializes the WorkflowConfiguration, its Workflow, and **all** objects that the Workflow is associated with into the `Run#execution_plan` field, and execution of the Run proceeds using that Execution Plan.  This allows a Workflow to be changed at any time without affecting any current Runs, and also preserves a record of the SQL that produced the Run results.

- **SqlSnippet**: A SQL Snippet is a fragment of SQL that may be reused in multiple Transforms by referencing its slug surrounded a colon on either side, e.g. `:slug_here:`. The system will interpolate the Snippet into the Transform SQL when generating an ExecutionPlan. Snippets may themselves contain parameter references, which will be resolved as described above *after* Snippet interpolation.

## Use cases

I have used this application in two major efforts at BrightBytes:

1) Defining the T portion of an ETL of monthly, per-customer data updates. A series of Workflows defines the source and target schemas, loads a Customer Extract from S3, Transforms it into a format amenable for loading into a Data Warehouse whose schema I designed in the process of writing the Workflow Transforms, and exports the results to S3.

2) Defining one Workflow for loading from S3 and another directly-dependent (through schema-referencing) Workflow for z-score normalizing, outlier-cleaning, scaling, (primitively-)imputing, and storing an ML feature repository; additional Workflows export row & column subsets of the repository to S3 as Training/Test/Validation data sets for various deep-learning models to chew on.

## Run Management

This application uses Sidekiq via Active::Job for parallelization of Runs, Transforms, and DataQualityReports.

To monitor Sidekiq locally or once deployed, click on Admin | Sidekiq in the application.

## <a name="demo_workflow">Demo Workflow</a>

This application comes with a rather pathetic Demo Workflow that was ported from an ancestral app.

In that application, it was a pre-requirement-specification Demo Workflow intended to be sufficiently complex for basic validation and testing.

In and of itself, it's meaningless, but it does provide a few limited examples of how to use this application, and is itself also used by the test suite.

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
rake heroku:maint:on

# Turn off Heroku maint mode
rake heroku:maint:off

# Deploy to Herou using the eponymous .git/config repo
rake heroku:deploy

# Download the production DB locally
rake heroku:download

# Upload a downloaded production DB into the Dev ENV
rake heroku:upload:development
```

To deploy to Heroku, you'll need 3 Heroku AddOns: Postgres, Redis (for Sidekiq), and SendGrid.

You'll only need one 1x Sidekiq Worker dyno if all Workflows will be run on Postgres.

However, to also run Workflows on Redshift, you'll need a 2nd Worker Heroku Resource of circa four 1x Sidekiq Worker dynos; see [Running Workflows on Redshift](#redshift_support) for more.

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

# Required for User Auth email and the Notification email
MAIL_SENDER='no-reply@somewhere.com'

# App URL
PRODUCTION_HOST=

# These are required
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

## <a name="redshift_support">Running Workflows on Redshift</a>

Configuring the application on Heroku to run using Redshift requires the following steps:

1) Set the 5 Redshift-related environment variables.  (Coming soon a future release, all these but the password will be encapsulated by an entity manipulable in the application, though the password will still need to be set by an environment variable.)

2) Enable the `worker_redshift` Heroku Worker Resource (it's defined in this application's `Procfile`), and set the number of 1X dynos to the level of parallelism desired.  (Mine is currently set to 4.)

- (NB: I'd recommend only configuring the app to use Redshift on your local machine if you are not also deploying to Heroku; it's just too easy for the 2 apps to collide Run names in 1 Redshift DB.)

Configuring a Workflow to run on Redshift requires the following steps:

1) Create a WorkflowConfiguration with the `Redshift?` attribute flagged.

2) If importing from and/or exporting to S3, in the same WorkflowConfiguration be sure to set at least the appropriate `CREDENTIALS 'aws_iam_role=arn:aws:iam::...'` in the Import Transform Options and/or Export Transform Options fields.

## Environment Setup for local development

See [Local Dev Env Setup](https://github.com/brightbytes/sql-cms/wiki/Local-Dev-Env-Setup) if you are new to setting up your machine to work on a Rails app.

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

    # Only set these if you need to run Workflows on Redshift, which you should strive to avoid as noted above
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

4) If your local environment requires a large amount of seed data, or if you just get sick of watching the migrations flash by when running `rake one_ring`, do the following:

  - Set up another git repo and clone it as a directory-sibling of the `sql-cms` repo, and create a subdirectory in that repo named `sql_cms`.

  - Set the ENV var `SEED_DATA_DUMP_REPO=` in your `.env` file to point to the new repo.

  - Run `rake one_ring` - which will invoke your `db:seed` task - and then run `rake db:data:dump` to create a Postgres dumpfile in the new repo

  - Ensure that your `db:seed` task checks whether it needs to generate data, and skips generation if not required.

  - Check in and push the new dump; future runs of `rake one_ring` will use it intead of running seeds.

## FAQ (that I frequently ask myself, to be clear)

Q: Why isn't this repo a gem?

A: It is quicker for me to make changes and deploy them by keeping this as an application for now. That is, I still need to use and change this application relatively frequently, and I'd rather not deal with the extra steps of releasing a new version of a gem and updating an app to us it for every change I make. However, there is probably tooling that would automate CD of this repo as a gem: once I have a chance to figure it out, this repo will become a gem.

Q: What new features does this app need?

A: [Future plans](https://github.com/brightbytes/sql-cms/wiki/Future-Plans)
