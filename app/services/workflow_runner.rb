# Creates and queues for execution a new Run for the supplied Workflow.
# Yeah, I tried to create a service.  The result is rather lame.  Bummer.
module WorkflowRunner

  extend self

  def run!(workflow:, creator:)
    plan = ActiveModelSerializers::SerializableResource.new(workflow).as_json
    run = workflow.runs.create!(creator: creator, execution_plan: plan)
    RunManagerJob.perform_later(run)
  end

end
