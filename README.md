# sql-cms

## What is it?

sql-cms is a standalone application that stores and runs Workflows comprised of SQL-based Transforms, Transform Validations, and Data Quality Reports.

When run, a Workflow creates a new Postgres/Redshift schema for the Run, and in that schema may execute DDL, load data files from S3, transform the loaded data via DML, validate the transformed data using SQL, and export new data files back out to S3.

## So what?

The organization of SQL expressions in a Workflow CMS that namespaces operations into Postgres/Redshift schemas and under S3 prefixes confers the following benefits:

- A given Workflow may be associated with multiple Customers, each having their own source S3 data files, and that data will proceed through identical processing steps at runtime.

- The user-specified dependency DAG of Transforms within a Workflow allows all sibling Transforms (siblings in the leaf-to-parent direction) and all Data Quality Reports to be executed in parallel.

- Similarly, Workflows themselves may also depend upon other Workflows, with the DAG thus defined also permitting parallel execution of Transforms and Data Quality Reports. Furthermore, due to their composability, a given Workflow's Transforms and Data Quality Reports may be reused by any number of other Workflows.

- Because it is stored in the context of a Postgres/Redshift schema, the data produced by a given Workflow Run may be referenced by any other Workflow Run.  This is useful when source S3 data files are huge: create a Workflow that loads the data, Run it once, and then create separate Workflows that Transform the loaded data by referencing schema-prefixed table names.



## Now what?





The following entities exist in the **public** Postgres schema, and together they realize the application:

- **User**: An Analyst possessing basic knowledge of SQL, or an ETL SQL Developer.  No knowledge of programming is required to use this application: only knowledge of SQL.

- **Customer**: The Customer with which a WorkflowConfiguration may be associated

- **Workflow**: A named collection of the following, each via a `has_many` relationship:

  - Various types of SQL Transform and their TransformDependencies and TransformValidations and their Validations

  - DataQualityReports, via WorkflowDataQualityReports

  - Other Workflows, via WorkflowDependency

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
- dump repo: in rake tasks section


## FAQ

Q: Why isn't this repo a gem?

A: It is quicker for me to make changes and deploy them by keeping this as an application for now. That is, I need to use and change this application relatively frequently, and I'd rather not deal with the extra steps of releasing a new version of a gem and updating the app to us it for every change I make. However, there is probably tooling that would automate CD of this repo as a gem: once I have a chance to figure it out, this repo will become a gem.





## Run Management

This application uses Sidekiq via Active::Job for parallelization of Runs, Transform groups, and DataQualityReports.  Details may be found in `app/jobs/`.

## Demo Workflow

This application comes with a rather lame Demo Workflow that was ported from an ancestral app.  There, it was a pre-requirement-specification Demo Workflow intended to be sufficiently complex to test the application.  In and of itself, it's meaningless, but it does provide a few limited examples of how to use this system, and also serves to quickly validate that a production application is set up correctly.

A rake task is provided for uploading the demo files to s3; you may use it as follows:

```
rake demo:upload_to_s3['s3://bucket/path/you/want/']
```

## Heroku Deployment

There are a number of rake tasks in `lib/tasks/heroku.rake` for managing a Heroku deployment.

To deploy to Heroku, you'll need 3 AddOns: Postgres, Redis (for Sidekiq), and SendGrid.

You'll only need one 1x Sidekiq Worker dyno if all Workflows will be run on Postgres.  However, to also run Workflows on Redshift, you'll need a 2nd Worker Heroku Resource pool of ~4 1x Sidekiq Worker dynos

You'll want to configure the same environment variables on Heroku as you do for your local setup, [here](#env_vars)

## Running Workflows on Redshift



## [Future plans](https://github.com/brightbytes/sql-cms/wiki/Future-Plans)

## [Environment Setup for local development](https://github.com/brightbytes/sql-cms/wiki/Local-Dev-Env-Setup)

## Local Project Setup

1) <a name="env_vars"></a>Add environment variables

  * Create a .env file in your sql-cms project folder with the following contents; it will be automatically used by the `dotenv` gem:

    ```
    PORT=3000
    RACK_ENV=development
    LANG='en_US.UTF-8'
    TZ='US/Pacific' # Or whatever

    DEFAULT_S3_REGION='us-west-2'
    DEFAULT_S3_BUCKET=<your preferred default bucket here>

    MAIL_SENDER='someone@somewhere.com'

    # Only set this if you deploy somewhere
    PRODUCTION_HOST='your-app-name.herokuapp.com'

    # Only set this if you want to store a large quantity of seed data as a binary image (in a separate repository, of course)
    SEED_DATA_DUMP_REPO='/path/to/seed/data/dump/repo'

    # You must supply these. (Most folks already have these set up globally in their env.)
    AWS_ACCESS_KEY_ID=<your access ID here>
    AWS_SECRET_ACCESS_KEY=<your secret access key here>

    # I have these globally in my ENV, and they may be necessary for something I haven't run into yet ... but I suspect not
    AWS_ACCOUNT_ID=<your account ID here>
    AWS_REGION="us-west-2"

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
