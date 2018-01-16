require "#{Rails.root}/lib/tasks/heroku_task_helper"

namespace :heroku do

  include HerokuTaskHelper

  namespace :maint do

    task on: :environment do
      puts "Turning on maintenance mode ..."
      heroku_run("heroku maintenance:on && heroku scale worker=0")
    end

    task off: :environment do
      puts "Turning off maintenance mode ..."
      heroku_run("heroku maintenance:off && heroku scale worker=1")
    end

  end

  DOWNLOAD_DUMPFILE = File.join(Rails.root, '../latest_sql_cms.dump')

  task download: :environment do

    puts "Backing up the production DB and downloading that latest backup ..."

    heroku_run("heroku pg:backups:capture")
    heroku_run("heroku pg:backups:download -o #{DOWNLOAD_DUMPFILE}")

  end

  namespace :upload do

    task development: :environment do
      if File.exists?(DOWNLOAD_DUMPFILE)
        run("pg_restore --clean --no-acl --no-owner -h localhost -U postgres -d sql_cms_development #{DOWNLOAD_DUMPFILE}")
      else
        raise "You must first run `rake heroku:download` before you can upload to dev."
      end
    end

  end

  task deploy: :environment do
    GitChecker.check_git_status!
    GitChecker.check_access!
    Deployer.deploy!
  end

  module GitChecker

    extend self

    def check_access!
      if heroku_run("heroku info 2>&1") =~ /You do not have access/i
        exit_with_message("You do not have access to the SQL CMS application!")
      end
    end

    def check_git_status!
      puts "Running `git fetch` ... "
      `git fetch`
      if `git log ..origin/#{current_branch}`.present?
        exit(0) unless ask("There are new commits on the remote branch 'origin/#{current_branch}'. Are you sure you want to proceed?")
      end
      status_msg_a = `git status`.split(/(?:\n+)/)
      if status_msg_a[1] =~ /your.branch.is.ahead/i
        exit(0) unless ask("You have local, committed changes that have not been pushed to the remote.  Are you sure you want to proceed?")
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
      cmd = 'git branch 2> /dev/null | sed -e \'/^[^*]/d\' -e \'s/* \(.*\)/\1/\''
      result = `#{cmd}`
      raise "Unable to get the current branch name" if result.blank?
      result.strip
    end

  end

  module Deployer

    extend self

    def deploy!
      run_migrations = run_migrations?

      exit(0) if run_migrations && !ask("There are new migrations to run.  If you proceed,\n\n*** YOU WILL INCUR SITE DOWNTIME!!! ***\n\nDo you wish to proceed?", important: true)

      enter_maint_mode = run_migrations || ask("Would you like to turn on maintenance mode even though you don't have any migrations to run?", show_abort_message: false)

      if enter_maint_mode
        stay_in_maint_mode = ask('Would you like to stay in maintenance mode after deployment, e.g. to run some rake tasks?', show_abort_message: false)
        Rake::Task["heroku:maint:on"].invoke
      end

      push_release!

      # The restart is necessary to not have the web server gag
      heroku_run("heroku run --size=Performance rake db:migrate && heroku restart") if run_migrations

      if enter_maint_mode
        if stay_in_maint_mode
          dputs "********** NOTE: YOU ARE STILL IN MAINTENANCE MODE, AND MUST MANUALLY DISABLE IT VIA `rake heroku:maint:off` **********"
        else
          Rake::Task["heroku:maint:off"].invoke
        end
      end

      open_in_browser
    end

    private

    def push_release!
      puts "Deploying ..."
      puts(`git push heroku HEAD:master --force`)
    end

    def last_release_sha
      heroku_run("heroku releases | grep Deploy | head -n 1 | awk '{print $3}'")
    end

    def run_migrations?
      sha = last_release_sha
      # You can occasionally get false positives off this when an old migration is tweaked, but it's rare enough that it doesn't matter
      `git diff #{sha} db/migrate`.present?
    end

    def open_in_browser
      puts "Opening the site for inspection ..."
      sleep 2 # because removing maint mode takes a couple seconds to propagate
      heroku_run("heroku open")
    end


  end
end
