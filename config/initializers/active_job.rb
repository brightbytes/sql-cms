ActiveJob::Base.queue_adapter = :sidekiq
Sidekiq.default_worker_options = { backtrace: true, retry: 0 } # I don't need no stinkin' retries; Run#nuke_failed_steps_and_rerun! should suffice
Sidekiq.configure_server do |config|
  config.average_scheduled_poll_interval = 3
end
