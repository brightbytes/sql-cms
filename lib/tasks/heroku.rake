require "#{Rails.root}/lib/tasks/task_helper"

namespace :heroku do

  include TaskHelper

  namespace :maint do

    task on: :environment do
      puts "Turning on maintenance mode ..."
      ShellCommand.run("heroku maintenance:on && heroku ps:scale web=0 worker=0 worker_redshift=0")
    end

    task off: :environment do
      puts "Turning off maintenance mode ..."
      ShellCommand.run("heroku maintenance:off && heroku ps:scale web=1 worker=1 worker_redshift=4")
    end

  end

  DOWNLOAD_DUMPFILE = File.join(Rails.root, '../latest_sql_cms.dump')

  task download: :environment do

    puts "Backing up the production DB and downloading that latest backup ..."

    ShellCommand.run(
      "heroku pg:backups:capture",
      "heroku pg:backups:download -o #{DOWNLOAD_DUMPFILE}"
    )

  end

  namespace :upload do

    task development: :environment do
      if File.exists?(DOWNLOAD_DUMPFILE)
        # So that we can load locally even if the remote schema differs
        Rake::Task['db:recreate'].invoke
        ShellCommand.run("pg_restore --clean --no-acl --no-owner -h localhost -U postgres -d sql_cms_development #{DOWNLOAD_DUMPFILE}")
      else
        raise "You must first run `rake heroku:download` before you can upload to dev."
      end
    end

  end

  task deploy: :environment do
    GitChecker.check_git_status!
    GitChecker.check_heroku_access!
    Deployer.deploy!
  end

  module GitChecker

    extend self

    def check_heroku_access!
      if ShellCommand.run("heroku info 2>&1", quietly: true) =~ /You do not have access/i
        exit_with_message("You do not have access to the SQL CMS Heroku application!")
      end
    end

    def check_git_status!
      quietly { `git fetch` }

      if `git log ..origin/#{current_branch}`.present?
        exit_with_message(<<~MESSAGE)
          There are new commits on the remote branch 'origin/#{current_branch}'.
          You almost certainly need to include them in this deployment.
          Aborting so you can verify that `git pull` is the appropriate thing to do.
        MESSAGE
      end

      status_msg_a = `git status`.split(/(?:\n+)/)
      if status_msg_a[1] =~ /your.branch.is.ahead/i
        exit_with_message(<<~MESSAGE)
          You have local, committed changes on the branch '#{current_branch}' that have not been pushed to its remote, but that will be deployed.
          Therefore, please either push those changes to the '#{current_branch}' remote so that CI can run, or else uncommit and stash them.
        MESSAGE
      end

      unless status_msg_a.last =~ /nothing to commit/i
        exit(0) unless ask("You have local, uncommitted changes.  Are you sure you want to proceed?")
      end
    end

    private

    def exit_with_message(msg)
      puts "\n#{msg}\n"
      exit(0)
    end

    def current_branch
      `git rev-parse --abbrev-ref HEAD`&.strip.tap { |result| raise "Unable to get the current branch name" if result.blank? }
    end

  end

  module Deployer

    extend self

    def deploy!
      if run_migrations = run_migrations?
        if ask("There are new migrations to run.  If you proceed,\n\n*** YOU WILL INCUR SITE DOWNTIME!!! ***\n\nDo you wish to proceed?", important: true)
          Rake::Task["heroku:maint:on"].invoke
        else
          exit(0)
        end
      end

      push_release!

      if run_migrations
        # The restart is necessary to not have the web server gag
        ShellCommand.run("heroku run --size=performance-m rake db:migrate && heroku restart")
        Rake::Task["heroku:maint:off"].invoke
      end

      open_in_browser
    end

    private

    def push_release!
      puts "Deploying ..."
      puts(`git push heroku HEAD:master --force`)
    end

    def last_release_sha
      ShellCommand.run("heroku releases | grep Deploy | head -n 1 | awk '{print $3}'", quietly: true)
    end

    def run_migrations?
      sha = last_release_sha
      containing_branches = `git br --contains #{sha}`
      if containing_branches.blank? || containing_branches =~ /malformed object/
        dputs red_font("The commit deployed by the previous release no longer exists, presumably due to overly-aggressive squashing.\nSo, you now need to suss whether or not migrations should be run after deployment, and manually run them if so.\nYou may determine who deployed the missing release commit via `heroku releases`, and follow up with that individual.")
        false
      else
        # We don't want to run migrations if old migration files were edited; we only want to run it when new migration files were added since the last release
        `git diff #{sha} db/migrate | grep 'new file mode'`.present?
      end
    end

    def open_in_browser
      puts "Opening the site for inspection ..."
      sleep 2 # because removing maint mode takes a couple seconds to propagate
      `heroku open`
    end

  end
end
