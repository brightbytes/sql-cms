source 'https://rubygems.org'

ruby "2.5.0"

gem 'dotenv-rails', require: 'dotenv/rails-now'

# Use Puma as the app server
# gem 'puma'
# FIXME: Or maybe not, since Rails isn't threadsafe; revisit at some point ...
gem "unicorn" # app server

gem 'rails'
# gem 'acts_as_list'

# bundle exec rake doc:rails generates the API under doc/api.
# gem 'sdoc', '~> 0.4.0', group: :doc

# DB
gem "pg" # Postgres
gem 'activerecord5-redshift-adapter'
gem 'immigrant' # FK constraints
gem 'postgres-copy' # bulk import
gem 'postgresql_cursor' # postgres cursors!!
gem 'paranoia' # logical delete

gem 'active_model_serializers'

gem 'fast_blank' # for fast calls to String#blank? and String#present?

# Versioning
gem 'paper_trail'

gem 'aws-sdk-s3'

group :development, :test do

  gem 'thin' # appserver
  gem 'foreman' # another appserver

  gem 'annotate' # annotations of model files and routes file

  # gem 'pry-rails'

  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platform: :mri
end

group :development do
  # Access an IRB console on exception pages or by using <%= console %> anywhere in the code.
  gem 'web-console'
  gem 'listen'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  gem 'spring-watcher-listen'

  # gem 'slack-notifier'

  gem 'brakeman'
end

group :test do
  gem 'acts_as_fu' # active record tests

  gem 'simplecov', require: false

  gem 'rspec'
  gem 'rspec-rails'
  gem 'rspec-mocks'
  gem 'shoulda-matchers'

  gem 'database_cleaner'
  gem 'timecop'

  gem 'connection_pool'
end

group :staging, :qa, :production do
  # Heroku - avoid deprecation warnings.  Grouped because it screws up logging in Dev.
  gem 'rails_12factor'
end

# Admin
# Pinning to 1.1.0 because 1.2.x and 2.0.x break all delete links and all colorization of labels; no time to debug
gem 'activeadmin', '~>1.1.0'

# Authentication
gem 'devise'
gem 'devise-async'

# Authorization
gem "cancan"

# Async
gem "sidekiq"

# Monitoring
gem "newrelic_rpm"

# Exception reporting
# gem "sentry-raven"

gem 'factory_bot_rails'
gem 'ffaker'

# For prompting users in scripts
gem "highline"

# For lightweight requests to remote resources when ActiveResource is overkill - which sadly is most of the time
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

# Colorize sql
gem 'rouge'
