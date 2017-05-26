# frozen_string_literal: true
module Concerns::FinalizedRuntimeDuration

  extend ActiveSupport::Concern

  # Runs and Run Step Logs are immutable after processing has completed, so this should be safe ... and it's quicker than creating columns for it.
  def duration_seconds
    end_time = (running_or_crashed? ? Time.zone.now : updated_at)
    end_time - created_at
  end

end
