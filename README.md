# dpl-cms

This application is intended to be used by SQL Analysts with no knowledge of programming; only knowledge of SQL and the entity types presented below are required.

With it, one may create per-Customer Workflows of interdependent SQL Transforms that convert a set of pre-existing Import DataFiles on S3 to a set of newly-generated Export DataFiles on S3.

A Workflow may be Run multiple times, and each time the system will deposit its Export DataFiles in a namespaced S3 "directory". Every Run occurs within a newly-created Postgres schema.

The following entities exist in the **public** Postgres schema:

- **User**: An Analyst possessing basic knowledge of SQL

- **Customer**: The Customer with which every Workflow and DataFile must be associated

- **DataFile**: Associated with a Customer, and thus usable in multiple Workflows.  Comes in 2 varieties:

  - **Import DataFile**: A specification of the location of a tabular flat-file that already exists on S3 (e.g. a CSV file)

  - **Export DataFile**: A specification of the desired location to which the system will write a per-Run tabular flat-file on S3 (e.g. a CSV file)

- **Workflow**: A named, per-Customer collection of the following, each via a `has_many` relationship, and each described in detail below:

  - Various types of SQL Transform and their TransformDependencies, TransformValidations, and (for some types of Transform) DataFiles

  - DataQualityReports

  - Notifications

  - Runs and their RunStepLogs

- **Notification**: An association of a Workflow with a User for the purpose of notifying the User whenenever a Run of that Workflow successfully or unsuccessfully completes.

- **Transform**: A named, optionally-parametrized SQL query that may be optionally associated with an Import or Export DataFile, and that specifies one of the following Runners for the SQL:

  - **RailsMigrationRunner**: Evals the contents of the sql field as a Ruby Migration (because hand-writing boilerplate DDL sucks); supports every feature that Rails Migrations support.  If preferred, SQL Analysts uncomfortable with Ruby code may use the generic **SqlRunner** described below to author DDL ... though I'd recommend learning Rails Migration syntax, because it's much more convenient.

  - **CopyFromRunner**: Requires association with an Import DataFile, and requires that its sql field be a `COPY ... FROM STDIN ...` type of SQL statement

  - **SqlRunner**: Allows its sql field to be any type of DDL statement (CREATE) or DML statement (INSERT, UPDATE, DELETE, but not SELECT, since that would be pointless) other than those that read from or write to files (COPY, UNLOAD, LOAD).

  - **CopyToRunner**: Requires association with an Export DataFile, and requires that its sql field be a `COPY ... TO STDOUT ...` type of SQL statement

  - **AutoLoadRunner**: **Not yet implemented** - Will require only an association to an Import DataFile, and will introspect on the DataFile's header, create a table with string columns based upon the sql-identifier-coerced version of the headers, and load the table from the file.

  - **UnloadRunner**: **Not yet implemented** -  Will be a Redshift-specific version of CopyToRunner, to be added when Redshift support is added.

- **TransformDependency**: An association of one Transform with another where the Prerequisite Transform must be run before the Postrequisite Transform.  Every Workflow has a TransformDependency-based DAG that is resolved at Run-time into a list of groups of Transforms, where each Transform in a given group may be run in parallel with all other Transforms in that group.

- **TransformValidation**: An association of a Transform to a parameterized Validation that specifies the parameters required for the Validation.  When a TransformValidation fails, the system fails its associated Transform, and execution halts in failure after that Transform's group completes execution.

- **Validation**: A named, reusable, manditorily-parametrized SQL query that validates the result of a Transform via an intermediating TransformValidation's params, e.g. to verify that all rows in a table have a value for a given column, are unique, reference values in another table, etc.  Similar in intent to Rails Validations.  Upon failure, returns the IDs of all invalid rows.

- **DataQualityReport**: A named, optionally-parametrized SELECT SQL statement that is run after all Transforms have completed.  The system will store the tabular data returned by the SQL and also include that data in the Notification email that is sent after a successful Run.

- **Run**: A record of the postgres-schema_name (useful for debugging/examining data), current status, and execution_plan of a given Run of a Workflow.  When a User creates a Run for a Workflow, the system serializes the Workflow and **all** its dependent objects into the Run#execution_plan field, and execution of the Run proceeds against that field.  This allows a Workflow to be changed at any time without affecting any current Runs.

- **RunStepLog**: A per-Run record of the execution of a single Transform or DataQualityReport that in success cases stores the result of running the SQL, in failure cases stores TransformValidation failures, or - when the Step raises an Exception - the error details.

## Run Management

This application uses Sidekiq via Active::Job for parallelization of Runs, Transform groups, and DataQualityReports.  Details may be found in `app/jobs/`.

## Demo Workflow

This application comes with a Demo Workflow that was ported from an ancestral app.  There, it also was a pre-requirement-specification Demo Wokrflow intended to be sufficiently complex to test the application.  In and of itself, it's meaningless, but it does provide some examples of how to use this system.

## Future plans, with difficulty levels

- DIFFICULT: Create CustomerWorkflow join-entity and associated TransformConfig and DataQualityReportConfig entities, moving all parameterization of Transforms (#params & #data_file_id) and DataQualityReports (#params) into the respective Config classes.  Change Runs and Notifications to be associated with CustomerWorkflows This so that a single Workflow may be used by multiple Customers with different configuration, especially of Transform DataFiles.  Since this is a major refactor, I'm hesitant to do it ... but am spiking on it now.
- EASY: Remove DataFile entity, replacing with Transform (or TransformConfig, if the preceding item is finished first) attributes/methods.  This because DataFiles are unlikely to be reused by multiple workflows, and it's a low lift to re-specify if ever they need to be.  And, it just makes more sense for them to be part of the Transform, since, well, they conceptually are.
- EASY: Add support for uploading local files to an Import DataFile S3 location.  Assuming the previous item is finished first, this would occur on Transform#show.
- EASY: Attain complete BE test coverage (mostly there), and add FE coverage (there's none yet).
- DIFFICULT: Implement an S3 browser for the Import DataFile Create and Edit pages, so S3 URLs needn't be copy/pasted in.  (The BE work has commenced in `app/models/s3`.)
- EASY: Implement the Autoload Transform runner.
- DIFFICULT: Add a TransformDependency visualizer so that the entire Transform DAG of a Workflow may be viewed at once.
- MIDDLING: Add Redshift support, both for production and local development.
- MIDDLING: Maybe port to Convox, especially if it would facilitate Redshift support.
- MIDDLING: Add support for transferring files from an SFTP server to an Import DataFile S3 location, so that the system can read the raw files provided by our customers
- MIDDLING: Add an API and/or SQS integration for remote-triggering of Workflow Runs
- EASY: Add support for scheduling Workflows
- EASY: Open source this application after extracting everything BB-specific to dotenv ENV vars

## Environment Setup for local development

As cribbed from the clarity repo, to get the DPL CMS running natively on your local machine:

1) Install XCode from the Apple App Store - you need it to build native extensions of plugins and gems.

2) Install Homebrew - you need it to manage package installation and updates

  * Go to http://brew.sh/ and follow the installation instructions.
  * When prompted, install XCode command line tools.
  * At the end of the installation, run `brew doctor` as instructed.

3) Install Postgres version 9.4.x - you need the 9.4.x line because our other apps are using 9.4 in production

  * If you have one (or more!) previous version(s) of Postgres installed **and** you don't care about saving any data, first do the following for every previous version you have, substituting your version(s) for 9.3:

  ```
  sudo /Library/PostgreSQL/9.3/uninstall-postgresql.app/Contents/MacOS/installbuilder.sh
  ```

    Then, nuke the data folders and the stupid, useless ini file:

  ```
  sudo rm -rf /Library/PostgreSQL
  sudo rm /etc/postgres-reg.ini
  ```

    If you need to save data and upgrade it into your 9.4 installation, you're on your own, though you'll start by googling `pg_upgrade`

  * If you don't already have Postgres installed on your machine you can try these two options:


    * Use the "Graphical installer" from http://www.postgresql.org/download/macosx/

      * It may need to resize shared memory and reboot your system before continuing; that's OK

      * Accept all the defaults you're prompted for

      * When prompted, set the password for the postgres user as: test123

      * At the end of the RDBMS installation, do *not* install StackBuilder - you don't need it

      * After installation, you might need to add Postgres to your PATH variable: `export PATH=/Library/PostgreSQL/9.4/bin:$PATH`

      * If you want to easily type `psql` and be logged in and have your DB set to dpl-cms:

        * Create the file ~/.pgpass with these contents: `*:*:*:postgres:test123`

        * Add the following alias to your shell config file (.bashrc, .zshrc, etc): `alias psql='psql -Upostgres -w -d dpl_cms_development`

    * Or install version 9.4.x from http://postgresapp.com

        Then add `/Applications/Postgres.app/Contents/Versions/9.4/bin` to your $PATH.

    The data management Rake task use Postgres command-line utilities (`pg_dump`, most importantly), so make sure the correct version is in your $PATH by running `pg_dump --version`.

4) Install Redis

  ```
  brew install redis
  brew services start redis # to automatically run it at startup
  ```

  Note: The test and development environments use different redis databases, so when using the `redis-cli` command line interface remember to select proper one:

  ```
  redis-cli -n 0 // for development
  redis-cli -n 1 // for test
  ```

5) Install git and git bash completion: `brew install git bash-completion`

  * Follow instructions nested in the output of the above to add auto-loading of git bash completion in your .bashrc

6) Clone the git repo:

  ```
  git clone https://github.com/brightbytes/dpl-cms.git
  # Clone this only if you want slightly-faster `one_ring` time
  git clone https://github.com/brightbytes/bb_data.git
  ```

  Or use ssh if you prefer (You will need to generate an ssh key first. Instructions can be found here: https://help.github.com/articles/generating-an-ssh-key/)

  ```
  git clone git@github.com:brightbytes/dpl-cms.git
  git clone git@github.com:brightbytes/bb_data.git
  ```

 Configure git:

  In the dpl-cms repo directory, substitute the correct values and run the following:

  ```
  git config --global user.name "Your Name"
  git config --global user.email "you@brightbytes.net"
  ```

  Also, these configurations are required at Brightbytes:

  ```
  git config --global branch.master.mergeoptions "--no-ff"
  git config --global push.default simple
  git config --global remote.origin.push HEAD
  ```

  Add the remotes to your .git/config:

  ```
  [remote "heroku"]
	  url = https://git.heroku.com/dpl-cms.git
	  fetch = +refs/heads/*:refs/remotes/heroku/*
  ```
  Additional optional settings may be configured by running the following from the dpl-cms repo directory; feel free to review before executing:

  ```
  bin/git-config.sh
  ```

7) Install a ruby version manager (either rvm or rbenv, both described below)

  * Install rvm - you need it to manage the installed Ruby versions and gemsets

    See https://rvm.io for current instructions.  The last time I checked, they were:

    ```
    brew install gnupg gnupg2  # GnuPG
    gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3  # to verify authenticity of the download once downloaded
    \curl -sSL https://get.rvm.io | bash -s stable  # to download it
    ```

    * If you're running Lion, rvm will bitch at you to get gcc via 4 brew-related steps.  Control-C out and copy/paste those commands at the terminal prompt.

    * Deposit the following in your .bashrc (or .zshrc) and also run them now:

    ```
    export PATH=$PATH:$HOME/.rvm/bin # Add RVM to PATH so you can use it anywhere
    [[ -s "$HOME/.rvm/scripts/rvm" ]] && . "$HOME/.rvm/scripts/rvm" # Automatically prompt to install Ruby if it's not installed yet upon cd into a Ruby repo dir
    ```

    * CD into the dpl-cms directory and copy/paste the `rvm use` command to the terminal prompt.  If you're on on Mavericks and it fails, just run the command again, and it should succeed.

  * Or install rbenv

  ```
  brew update
  brew install rbenv
  rbenv init
  ```

  Refer to documentation at https://github.com/rbenv/rbenv for further details

## Project Setup

1) Add environment variables

  * Create a .env file in your dpl-cms project folder with the following contents:

    ```
    export PORT=3000
    export RACK_ENV=development

    # You must supply these to connect to S3:
    #  (If you are a SIS DPL dude, you already have these set up in your ~/.bb_ops/aws_user.env file, so move along: nothing to see here.)
    export AWS_ACCESS_KEY_ID=<your access ID here>
    export AWS_SECRET_ACCESS_KEY=<your secret access key here>

    # These aren't required, but I have them locally, and they may be necessary for something I haven't run into yet:
    export AWS_ACCOUNT_ID=<your account ID here>
    export AWS_REGION="us-west-2"
    ```

  * Use [dotenv](https://github.com/bkeepers/dotenv) to import this file automatically when you enter the `dpl-cms` directory.

  * OR, simply add your .env file to your .bashrc or .bash_profile

    ```
    source ~/<path_to_your>/.env
    ```

2) Reset your environment and load Postgres with the Demo Workflow:

  ```
  rake one_ring
  ```

  Run the above script every time you want to re-initialize your dev environment to baseline.

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
