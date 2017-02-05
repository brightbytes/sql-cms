class WorkflowTransformJob < ApplicationJob

  queue_as :high

  def perform(*args)
    # Do something later
  end
end
