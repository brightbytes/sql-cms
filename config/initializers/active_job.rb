ActiveJob::Base.queue_adapter = :sidekiq
Sidekiq.default_worker_options = { backtrace: true, retry: 3 } # We only have retries for the case where we exhaust the connection pool
Sidekiq.configure_server do |config|
  config.average_scheduled_poll_interval = 2
end
