# This is a
class RunManagerJob < ApplicationJob

  queue_as :default

  def perform(run_id)
    run = Run.find(run_id)
    # Check if all Run#run_step_logs succeeded; if not, exit
    # Since we wouldn't get here unless we're ready for the next step, check Run#status, and do the next steps
  end
end
