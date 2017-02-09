ActiveJob::Base.queue_adapter = :sidekiq
Sidekiq.default_worker_options = { backtrace: true, retry: 6 }
Sidekiq.configure_server do |config|
  config.average_scheduled_poll_interval = 5
end
