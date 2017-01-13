ActiveJob::Base.queue_adapter = :sidekiq
Sidekiq.default_worker_options = { 'backtrace' => true, 'retry' => 3 }
