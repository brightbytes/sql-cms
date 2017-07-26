web: bundle exec unicorn -p $PORT -c ./config/unicorn.rb
worker: bundle exec sidekiq -C config/sidekiq.yml -q mailers -q default
worker_redshift: bundle exec sidekiq -q redshift -c 1
