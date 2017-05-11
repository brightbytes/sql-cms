shared_examples 'cheesey dependency graph' do

  let!(:workflow_configuration) { create(:workflow_configuration) }

  let!(:workflow) { workflow_configuration.workflow }

  let!(:most_dependent_transform) { create(:transform, workflow: workflow) }
  let!(:first_child_transform) { create(:transform, workflow: workflow) }
  let!(:dependency_1) { create(:transform_dependency, prerequisite_transform: first_child_transform, postrequisite_transform: most_dependent_transform) }

  let!(:less_dependent_transform) { create(:transform, workflow: workflow) }
  let!(:dependency_2) { create(:transform_dependency, prerequisite_transform: less_dependent_transform, postrequisite_transform: most_dependent_transform) }

  let!(:another_less_dependent_transform) { create(:transform, workflow: workflow) }
  let!(:dependency_3) { create(:transform_dependency, prerequisite_transform: another_less_dependent_transform, postrequisite_transform: most_dependent_transform) }

  let!(:least_dependent_transform) { create(:transform, workflow: workflow) }
  let!(:dependency_4) { create(:transform_dependency, prerequisite_transform: least_dependent_transform, postrequisite_transform: less_dependent_transform) }

  let!(:dependency_5) { create(:transform_dependency, prerequisite_transform: least_dependent_transform, postrequisite_transform: another_less_dependent_transform) }

  let!(:independent_transform) { create(:transform, workflow: workflow) }

  let!(:another_workflow_transform) { create(:transform) }

end

shared_examples 'a workflow serialized into a run' do

  include_examples 'cheesey dependency graph'

  let!(:workflow_data_quality_report_1) { create(:workflow_data_quality_report, workflow: workflow, data_quality_report: DataQualityReport.table_count) }
  let!(:workflow_data_quality_report_2) { create(:workflow_data_quality_report, workflow: workflow, data_quality_report: DataQualityReport.table_count) }
  let!(:workflow_data_quality_report_3) { create(:workflow_data_quality_report, workflow: workflow, data_quality_report: DataQualityReport.table_count) }

  let!(:creator) { create(:user) }

  let!(:run) do
    workflow_configuration.runs.create!(creator: creator, execution_plan: workflow_configuration.serialize_and_symbolize)
  end
end
