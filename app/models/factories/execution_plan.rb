class ExecutionPlan

  class << self

    def create(workflow_configuration)
      execution_plan = workflow_configuration.serialize_and_symbolize.tap do |including_plan_h|
        # First, we merge all included workflows' Transform Groups and Data Quality Reports
        merged_included_workflow_h = merge_included_workflows!(
          workflow_configuration: workflow_configuration,
          included_workflows: workflow_configuration.workflow.included_workflows
        )
        if merged_included_workflow_h
          # Then, we change the including_plan_h so that all merged Transform Groups come before the including_workflow's Transform Groups
          reorder_workflow_transform_groups!(including_plan_h, merged_included_workflow_h)
          # And, we just merge Data Quality Reports, since no ordering is required (except in the UI, which demands alphabetical; dealt with in View)
          merge_workflow_data_quality_reports!(including_plan_h, merged_included_workflow_h)
        end
      end
      new(execution_plan)
    end

    def wrap(execution_plan_h)
      new(execution_plan_h)
    end

    private

    def merge_included_workflows!(workflow_configuration:, included_workflows:)
      return nil if included_workflows.empty?
      first_workflow, rest_workflows = included_workflows.first, included_workflows.last(included_workflows.size - 1)
      first_plan_h = create(WorkflowConfiguration.new(workflow: first_workflow)).to_hash # recursive call
      rest_workflows.each do |rest_workflow|
        rest_plan_h = create(WorkflowConfiguration.new(workflow: rest_workflow)).to_hash # recursive call
        merge_workflow_data_quality_reports!(first_plan_h, rest_plan_h)
        merge_workflow_transform_groups!(first_plan_h, rest_plan_h)
      end
      first_plan_h
    end

    # NB: Side-effect!
    def merge_workflow_data_quality_reports!(including_plan_h, included_plan_h)
      including_plan_h[:workflow_data_quality_reports] ||= []
      included_plan_h[:workflow_data_quality_reports] ||= []
      if including_plan_h[:workflow_data_quality_reports].present? || included_plan_h[:workflow_data_quality_reports].present?
        including_plan_h[:workflow_data_quality_reports] = included_plan_h[:workflow_data_quality_reports] + including_plan_h[:workflow_data_quality_reports]
      end
    end

    # NB: Side-effect!
    def merge_workflow_transform_groups!(including_plan_h, included_plan_h)
      including_plan_h[:ordered_transform_groups] ||= []
      included_plan_h[:ordered_transform_groups] ||= []
      if including_plan_h[:ordered_transform_groups].present? || included_plan_h[:ordered_transform_groups].present?
        num_iterations = [including_plan_h[:ordered_transform_groups].size, included_plan_h[:ordered_transform_groups].size].max - 1
        (0..num_iterations).each do |i|
          included_ordered_transform_groups = included_plan_h[:ordered_transform_groups][i]
          if included_ordered_transform_groups.present?
            including_plan_h[:ordered_transform_groups][i] ||= []
            including_plan_h[:ordered_transform_groups][i] += included_ordered_transform_groups
          end
        end
      end
    end

    # NB: Side-effect!
    def reorder_workflow_transform_groups!(including_plan_h, included_plan_h)
      if included_groups = included_plan_h[:ordered_transform_groups]
        including_plan_h[:ordered_transform_groups] = included_groups + (including_plan_h[:ordered_transform_groups] || [])
      end
    end
  end

  attr_reader :execution_plan

  def initialize(execution_plan_h)
    @execution_plan = execution_plan_h
  end

  alias_method :to_hash, :execution_plan

  def transform_group(step_index)
    execution_plan[:ordered_transform_groups][step_index] if execution_plan.present?
  end

  def transform_group_transform_ids(step_index)
    transform_group(step_index)&.map { |h| h.fetch(:id, nil) }
  end

  def transform_plan(step_index:, transform_id:)
    if base_plan = transform_group(step_index)&.detect { |h| h[:id] == transform_id }
      base_plan.merge!(
        s3_region_name: execution_plan[:s3_region_name],
        s3_bucket_name: execution_plan[:s3_bucket_name],
        s3_file_path: execution_plan[:s3_file_path],
        import_transform_options: execution_plan[:import_transform_options],
        export_transform_options: execution_plan[:export_transform_options]
      ) if base_plan[:interpolated_s3_file_name].present?
      base_plan.deep_symbolize_keys
    end
  end

  def workflow_data_quality_reports
    execution_plan[:workflow_data_quality_reports] if execution_plan.present?
  end

  def workflow_data_quality_report_plan(workflow_data_quality_report_id)
    workflow_data_quality_reports&.detect { |h| h[:id] == workflow_data_quality_report_id }&.symbolize_keys
  end

  def workflow_data_quality_report_ids
    workflow_data_quality_reports&.map { |h| h.fetch(:id, nil) }
  end

  def use_redshift?
    execution_plan[:redshift]
  end

end
