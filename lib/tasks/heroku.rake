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

    heroku_run("heroku pg:backups:download -o #{DOWNLOAD_DUMPFILE}")

  end

  namespace :upload do

    task development: :environment do
      if File.exists?(DOWNLOAD_DUMPFILE)
        run("pg_restore --clean --no-acl --no-owner -h localhost -U postgres -d dpl_cms_development #{DOWNLOAD_DUMPFILE}")
      else
        raise "You must first run `rake heroku` before you can upload to dev."
      end
    end

  end

end
