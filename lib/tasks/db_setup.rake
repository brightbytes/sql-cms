# frozen_string_literal: true

require "#{Rails.root}/lib/tasks/task_helper"

require 'dotenv/tasks'

namespace :db do

  include TaskHelper

  desc 'Drop and recreate the local, dev DB'

  task recreate: ['db:drop', 'db:create']

  desc 'Drops and recreates the dev and test DBs, loads, migrates, reannotates, and seeds the dev DB, runs all specs'

  task init: ['db:recreate', 'db:data:load_dump', 'db:migrate', 'db:seed', 'db:test:prepare', :spec]

  namespace :data do

    # Need this to use the ENV var :-(
    module PathHelpers

      extend self

      def env_var_present?
        dump_repo.present?
      end

      def full_dump_path
        @full_dump_path ||= Rails.root.join(dump_repo, 'sql_cms')
      end

      def full_dump_path_and_file
        @full_dump_path_an_file ||= "#{full_dump_path}/dump.Fc".gsub(/\/{2,}/, '/')
      end

      private def dump_repo
        ENV['SEED_DATA_DUMP_REPO'].presence
      end
    end

    DB_CONFIG = YAML.load(ERB.new(File.read("#{Rails.root}/config/database.yml")).result)[Rails.env]

    desc "Dumps the local dev DB to the `sql_cms` directory in the ENV['SEED_DATA_DUMP_REPO'] repo, for later use by db:data:load"

    task dump: [:environment, :dotenv] do
      raise "This task is only for use in a development environment" unless Rails.env.development?

      if PathHelpers.env_var_present?
        if File.exists?(PathHelpers.full_dump_path)
          dputs "Dumping PostgreSQL for the SQL CMS Application ..."
          run("PGPASSWORD=#{DB_CONFIG["password"]} pg_dump --clean --oids --format=custom --no-password --username #{DB_CONFIG["username"]} --dbname #{DB_CONFIG["database"]} --host #{DB_CONFIG["host"]} --no-owner --file #{PathHelpers.full_dump_path_and_file}")
        else
          raise "Unable to dump your local DB because '#{PathHelpers.full_dump_path}' doesn't exist."
        end
      else
        raise "The env var SEED_DATA_DUMP_REPO is not defined."
      end
    end

    desc "Loads tables from a dump file in the `sql_cms` directory in the ENV['SEED_DATA_DUMP_REPO'] repo"

    task load_dump: [:environment, :dotenv] do
      raise "This task is only for use in a development environment" unless Rails.env.development?

      if PathHelpers.env_var_present?
        if File.exists?(PathHelpers.full_dump_path_and_file)
          dputs "Loading PostgreSQL for SQL CMS Application ..."
          run("PGPASSWORD=#{DB_CONFIG["password"]} pg_restore -Fc -w -U #{DB_CONFIG["username"]} -d #{DB_CONFIG["database"]} -h #{DB_CONFIG["host"]} #{PathHelpers.full_dump_path_and_file}")
        else
          dputs "Skipping dumpfile load because it doesn't exist at '#{PathHelpers.full_dump_path_and_file}'"
        end
      else
        dputs "Skipping dumpfile load because the env var SEED_DATA_DUMP_REPO is not defined."
      end
    end

  end

end

desc "One Task to rule them all, One Task to find them, One Task to bring them all, and in the Darkness bind them"
task one_ring: 'db:init'
