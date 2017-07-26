web: bundle exec unicorn -p $PORT -c ./config/unicorn.rb
worker: bundle exec sidekiq -C config/sidekiq.yml -q mailers -q default
# Start a separate process with only 1 worker exclusively for processing Redshift-related jobs.
# This is required because changing a connection on the fly is not threadsafe in Rails.
worker_redshift: bundle exec sidekiq -q redshift -c 1
