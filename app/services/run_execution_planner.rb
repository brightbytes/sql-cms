# Determins the contents of the Run#execution_plan for the supplied Workflow, which comprises a serialized version of the Workflow *and* a serialized version
#  of the DependencyGroups.  Delegates part of its work to TransformDependencyGrouper
module RunExecutionPlanner

  extend self

  def create_run!(workflow:, creator:)
    base_plan = ActiveModelSerializers::SerializableResource.new(Workflow.first).as_json
    run = workflow.runs.build(creator: creator, execution_plan: plan)

  end

end
