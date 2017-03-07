class ExecutionPlan

  class << self

    def create(workflow)
      execution_plan_h = workflow.serialize_and_symbolize.tap do |including_plan_h|
        workflow.included_workflows.each do |included_workflow|
          included_plan_h = included_workflow.serialize_and_symbolize
          merge_data_quality_reports!(including_plan_h, included_plan_h)
          merge_transforms!(including_plan_h, included_plan_h)
        end
      end
      new(execution_plan_h)
    end

    private

    # NB: Side-effect!
    def merge_data_quality_reports!(including_plan_h, included_plan_h)
      including_plan_h[:data_quality_reports] ||= []
      included_plan_h[:data_quality_reports] ||= []
      if including_plan_h[:data_quality_reports].present? || included_plan_h[:data_quality_reports].present?
        including_plan_h[:data_quality_reports] += included_plan_h[:data_quality_reports]
      end
    end

    # NB: Side-effect!
    def merge_transforms!(including_plan_h, included_plan_h)
      including_plan_h[:ordered_transform_groups] ||= []
      included_plan_h[:ordered_transform_groups] ||= []

      if including_plan_h[:ordered_transform_groups].present? || included_plan_h[:ordered_transform_groups].present?
        num_iterations = [including_plan_h[:ordered_transform_groups].size, included_plan_h[:ordered_transform_groups].size].max - 1
        (0..num_iterations).each do |i|
          including_plan_h[:ordered_transform_groups][i] += included_plan_h[:ordered_transform_groups][i]
        end
      end
    end
  end

  attr_reader :execution_plan_h

  def initialize(execution_plan_h)
    @execution_plan_h = execution_plan_h
  end

  alias_method :to_hash, :execution_plan_h

  # FIXME - Extract all the Run#execution_plan helpers from the Run object to here!

end
