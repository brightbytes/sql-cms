ActiveJob::Base.queue_adapter = :sidekiq
Sidekiq.default_worker_options = { backtrace: true, retry: 6 } # maybe no retries would be better
Sidekiq.configure_server do |config|
  config.average_scheduled_poll_interval = (Rails.env.development? ? 2 : 5)
end
