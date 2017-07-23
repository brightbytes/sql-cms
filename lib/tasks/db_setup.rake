# frozen_string_literal: true

require "#{Rails.root}/lib/tasks/task_helper"

namespace :db do

  include TaskHelper

  desc 'Drop and recreate the local, dev DB'

  task recreate: ['db:drop', 'db:create']

  desc 'Drops and recreates the dev and test DBs, loads, migrates, reannotates, and seeds the dev DB, runs all specs'

  task init: ['db:recreate', 'db:data:load_dump', 'db:migrate', 'db:seed', 'db:test:prepare', :spec]

  # Don't care to do this right now.
  # desc 'Create the shared_extensions schema, whose contents may be used by any Run'

  # task extensions: :environment  do
  #   # FIXME - COME UP WITH A BETTER WAY OF CONDITIONALIZING THIS CONFIG
  #   if ENV['CREATE_FDW'] # Gated so that this only goes down for my installation.
  #     host = ENV['FDW_HOST']
  #     port = ENV['FDW_PORT']
  #     dbname = ENV['FDW_DBNAME']
  #     user = ENV['FDW_USER']
  #     password = ENV['FDW_PASSWORD']
  #     [
  #       'CREATE SCHEMA IF NOT EXISTS shared_extensions',
  #       'CREATE EXTENSION IF NOT EXISTS postgres_fdw SCHEMA shared_extensions',
  #       'CREATE EXTENSION IF NOT EXISTS dblink SCHEMA shared_extensions',
  #     ].each { |sql| ActiveRecord::Base.connection.execute(sql) }
  #     [
  #       "CREATE SERVER foreign_server FOREIGN DATA WRAPPER postgres_fdw OPTIONS (host '#{host}', port '#{port}', dbname '#{dbname}', sslmode 'require')",
  #       "CREATE USER MAPPING FOR PUBLIC SERVER foreign_server OPTIONS (user '#{user}', password '#{password}')"
  #     ].each do |sql|
  #       Apartment::Tenant.switch('shared_extensions') { Apartment.connection.transaction { Apartment.connection.execute(sql) } }
  #     end
  #   end
  # end

  namespace :data do

    FULL_DUMP_PATH = Rails.root.join("../bb_data/db_dump/sql_cms/")
    FULL_DUMP_PATH_AND_FILE = FULL_DUMP_PATH + "dump.Fc"
    DB_CONFIG = YAML.load(ERB.new(File.read("#{Rails.root}/config/database.yml")).result)[Rails.env]

    desc "Dumps the local dev DB to the designated location in the bb_data repo, for later use by db:data:load"

    task dump: :environment do
      raise "This task is only for use in a development environment" unless Rails.env.development?

      if File.exists?(FULL_DUMP_PATH)
        dputs "Dumping PostgreSQL for the SQL CMS Application ..."
        run("PGPASSWORD=#{DB_CONFIG["password"]} pg_dump --clean --oids --format=custom --no-password --username #{DB_CONFIG["username"]} --dbname #{DB_CONFIG["database"]} --host #{DB_CONFIG["host"]} --no-owner --file #{FULL_DUMP_PATH_AND_FILE}")
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

# Rake::Task["db:create"].enhance do
#   Rake::Task["db:extensions"].invoke
# end

# Rake::Task["db:test:purge"].enhance do
#   Rake::Task["db:extensions"].invoke
# end

desc "One Task to rule them all, One Task to find them, One Task to bring them all, and in the Darkness bind them"
task one_ring: 'db:init'
