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

  DOWNLOAD_DUMPFILE = File.join(Rails.root, '../latest_dpl_cms.dump')

  task download: :environment do

    puts "Downloading latest backup ..."

    public_url = heroku_run("heroku pg:backups public-url --remote #{phase}")
    run("curl -o #{DOWNLOAD_DUMPFILE} '#{public_url}'")

  end

  namespace :upload do

    task development: :environment do
      if File.exists?(DOWNLOAD_DUMPFILE)
        run("pg_restore --verbose --clean --no-acl --no-owner -h localhost -U postgres -d clarity_survey_data_development #{DOWNLOAD_DUMPFILE}")
        Rake::Task['db:blur'].invoke
      else
        raise "You must first run `rake heroku:download:staging` or `rake heroku:download:production` before you can upload to dev."
      end
    end

  end

end
