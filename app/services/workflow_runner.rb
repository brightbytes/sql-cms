# Creates and executes a new Run for the supplied Workflow.  Delegates part of its work to RunExecutionPlanner and TransformRunner.
module WorkflowRunner

  extend self

  def run!(workflow:, creator:)
    run = RunExecutionPlanner.create_run!(workflow: workflow, creator: creator)
    RunManagerJob.perform_later(run)
  end

end
