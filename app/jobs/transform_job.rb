class TransformJob < ApplicationJob

  def perform(run_id:, transform_h:)
    run = Run.find(run_id)

    # run.with_run_status_tracking(self) { transform.send(:run, run: run, pipeline_transform: self) } &&
    #   Run.all_succeeded?(transform_validations.map { |transform_validation| transform_validation.run(run) })

    # This is private because Transforms should always be invoked through PipelineTransform#run (which delegates to this) since it adds run status tracking
    # private def run(run:, pipeline_transform:)
    #   # This default implementation works for everything except CopyFrom and CopyTo, which both require interaction with an IO object
    #   run.execute_in_schema(pipeline_transform.interpolated_dml)
    # end

  end
end
