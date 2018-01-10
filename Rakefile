# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require_relative 'config/application'

Rails.application.load_tasks

begin
  require 'rspec/core/rake_task'
  RSpec::Core::RakeTask.new(:spec)
  task default: :spec
rescue LoadError
end

# Running migrations tries to dump the structure on Heroku.  This fixes that.
Rake::Task["db:structure:dump"].clear if Rails.env.in?(['staging', 'production']) # wanna use heroku_env.rb here, but can't
