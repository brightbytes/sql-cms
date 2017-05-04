source 'https://rubygems.org'

ruby "2.4.1"

gem 'dotenv-rails', groups: [:development, :test], require: 'dotenv/rails-now'

# Use Puma as the app server
# gem 'puma', '~> 3.0'
# Or maybe not, since Rails isn't threadsafe ...
gem "unicorn" # app server

gem 'rails'
# gem 'acts_as_list'

# bundle exec rake doc:rails generates the API under doc/api.
# gem 'sdoc', '~> 0.4.0', group: :doc

# DB
gem "pg" # Postgres
gem 'immigrant' # FK constraints
gem 'postgres-copy' # bulk import
gem 'postgresql_cursor' # postgres cursors!!
# Commented out because it doesn't work with Rails 5.1
# gem 'acts_as_paranoid' # logical delete
gem 'paranoia' # logical delete
gem 'apartment' # multi-tenancy (i.e. Postgres Schemas)

gem 'active_model_serializers', '~> 0.10.0'

gem 'fast_blank' # for fast calls to String#blank? and String#present?

# K/V store
# gem "redis"

# Versioning
gem 'paper_trail'

# AWS ... duh :-)
gem 'aws-sdk'

group :development, :test do

  gem 'thin' # appserver
  gem 'foreman' # another appserver

  # This newer, unreleased version fixes model annotations of funky indexes, and (unlike an earlier ref) doesn't break route annotation.
  gem 'annotate', github: 'ctran/annotate_models', ref: "8341983f263e662c5e528b04d0eeec908daec1ad"

  gem 'pry-rails'

  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platform: :mri
end

group :development do
  # Access an IRB console on exception pages or by using <%= console %> anywhere in the code.
  gem 'web-console', '>= 3.3.0'
  gem 'listen', '~> 3.0.5'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'

  # gem 'slack-notifier'

  # gem 'rubocop'
end

group :test do
  gem 'acts_as_fu' # active record tests

  gem 'simplecov', require: false

  gem 'rspec'
  gem 'rspec-rails'
  gem 'rspec-mocks'
  gem 'shoulda'

  gem 'database_cleaner'
  gem 'timecop'

  # gem 'fakeredis'
  gem 'connection_pool'
end

group :staging, :qa, :production do
  # Heroku - avoid deprecation warnings.  Grouped because it fucks up logging in Dev.
  gem 'rails_12factor'
end

# Authentication
gem 'devise', git: 'https://github.com/gogovan/devise.git', branch: 'rails-5.1' # This and the following line are to support rails 5.1
gem 'erubis'
# This is removed because ^^ doesn't support it
# gem 'devise-async'

# Authorization
gem "cancan"

# Async
# gem "daemons"
gem "sidekiq"

# Monitoring
gem "newrelic_rpm"

# Exception reporting
# gem "sentry-raven"

# Admin
gem 'inherited_resources', github: 'activeadmin/inherited_resources' # required to install AA with Rails 5
gem 'activeadmin', github: 'activeadmin'

gem 'factory_girl_rails'
gem 'ffaker'

# For prompting users in scripts
gem "highline"

# For lightweight requests to remote resources when ActiveResource is overkill
# gem 'rest-client'

# Use SCSS for stylesheets
gem 'sass-rails', '~> 5.0'

# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'
# Use CoffeeScript for .coffee assets and views
gem 'coffee-rails', '~> 4.2'
# Use jquery as the JavaScript library
gem 'jquery-rails'
# Turbolinks makes navigating your web application faster. Read more: https://github.com/turbolinks/turbolinks
gem 'turbolinks', '~> 5'

# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.5'
# Pin thor to stop an annoying jbuilder error from appearing:
gem 'thor', '0.19.1'
