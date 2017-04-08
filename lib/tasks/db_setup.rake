# frozen_string_literal: true

require "#{Rails.root}/lib/tasks/task_helper"

namespace :db do

  include TaskHelper

  desc 'Drop and recreate the local, dev DB'

  task recreate: ['db:drop', 'db:create']

  desc 'Drops and recreates the dev and test DBs, loads, migrates, reannotates, and seeds the dev DB, runs all specs'

  task init: ['db:recreate', 'db:data:load_dump', 'db:migrate', 'db:seed', 'db:test:prepare', :spec]

  namespace :data do

    FULL_DUMP_PATH = Rails.root.join("../bb_data/db_dump/sql_cms/")
    FULL_DUMP_PATH_AND_FILE = FULL_DUMP_PATH + "dump.Fc"
    DB_CONFIG = YAML.load(ERB.new(File.read("#{Rails.root}/config/database.yml")).result)[Rails.env]

    desc "Dumps the local dev DB to the designated location in the bb_data repo, for later use by db:data:load"

    task dump: :environment do
      raise "This task is only for use in a development environment" unless Rails.env.development?

      if File.exists?(FULL_DUMP_PATH)
        dputs "Dumping PostgreSQL for the SQL CMS Application ..."
        run("PGPASSWORD=#{DB_CONFIG["password"]} pg_dump -c -o -Fc -w -U #{DB_CONFIG["username"]} -d #{DB_CONFIG["database"]} -h #{DB_CONFIG["host"]} --no-owner -f #{FULL_DUMP_PATH_AND_FILE}")
      else
        raise "You can't dump your local DB because #{FULL_DUMP_PATH} doesn't exist."
      end
    end

    desc "Loads tables from the bb_data dump file"

    task load_dump: :environment do
      raise "This task is only for use in a development environment" unless Rails.env.development?

      if File.exists?(FULL_DUMP_PATH_AND_FILE)
        dputs "Loading PostgreSQL for SQL CMS Application ..."
        run("PGPASSWORD=#{DB_CONFIG["password"]} pg_restore -Fc -w -U #{DB_CONFIG["username"]} -d #{DB_CONFIG["database"]} -h #{DB_CONFIG["host"]} #{FULL_DUMP_PATH_AND_FILE}")
      else
        dputs "Skipping load of dumpfile, since it doesn't exist."
      end
    end

  end

end

desc "One Task to rule them all, One Task to find them, One Task to bring them all, and in the Darkness bind them"
task one_ring: 'db:init'
