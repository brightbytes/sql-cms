# frozen_string_literal: true

require "#{Rails.root}/lib/tasks/task_helper"

namespace :db do

  include TaskHelper

  desc 'Drop and recreate the local, dev DB'

  task recreate: ['db:drop', 'db:create']

  desc 'Drops and recreates the dev and test DBs, loads, migrates, reannotates, and seeds the dev DB, runs all specs'

  # NOTE - Since the local dev DB can (and now does) contain all the data from a staging or prod dump, we can load the dump before the migration here.
  #        (This is not possible in larger repos, making `one_ring` far more of a pain to maintain there.  But, here, it can shine in all its intended glory.)
  task init: ['db:recreate', 'db:data:load_dump', 'db:migrate', 'db:seed', 'db:test:prepare', :spec]

  namespace :data do

    FULL_DUMP_PATH = Rails.root.join("../bb_data/db_dump/dpl_cms/dump.Fc")
    DB_CONFIG = YAML.load(ERB.new(File.read("#{Rails.root}/config/database.yml")).result)[Rails.env]

    desc "Dumps the local dev DB to the designated location in the bb_data repo, for later use by db:data:load"

    task dump: :environment do
      raise "This task is only for use in a development environment" unless Rails.env.development?

      dputs "Dumping PostgreSQL for the DPL CMS Application ..."
      run("PGPASSWORD=#{DB_CONFIG["password"]} pg_dump -c -o -Fc -w -U #{DB_CONFIG["username"]} -d #{DB_CONFIG["database"]} -h #{DB_CONFIG["host"]} --no-owner -f #{FULL_DUMP_PATH}")
    end

    desc "Loads tables from the bb_data dump file"

    task load_dump: :environment do
      raise "This task is only for use in a development environment" unless Rails.env.development?

      dputs "Loading PostgreSQL for DPL CMS Application ..."

      run("PGPASSWORD=#{DB_CONFIG["password"]} pg_restore -Fc -w -U #{DB_CONFIG["username"]} -d #{DB_CONFIG["database"]} -h #{DB_CONFIG["host"]} #{FULL_DUMP_PATH}")
    end

  end

end

desc "One Task to rule them all, One Task to find them, One Task to bring them all, and in the Darkness bind them"
# FIXME: Change to use db:init once we have a dumpfile
task one_ring: 'db:init'
