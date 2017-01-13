class ApplicationJob < ActiveJob::Base

  OMG_ITS_FULL_OF_STARS = ('*' * 80)

  rescue_from ActiveJob::DeserializationError do |e|
    bt = Rails.backtrace_cleaner.clean(e.backtrace).join("\n")
    Rails.logger.error("\n#{OMG_ITS_FULL_OF_STARS}\nERROR: The ActiveRecord object for this job no longer exists. Ignoring. Original exception:\n#{e.class}: #{e.message}\n#{bt}\n#{OMG_ITS_FULL_OF_STARS}\n")
  end

end
