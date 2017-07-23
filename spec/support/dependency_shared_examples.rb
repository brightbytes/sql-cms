shared_examples 'cheesey transform dependency graph' do

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

  include_examples 'cheesey transform dependency graph'

  let!(:workflow_data_quality_report_1) { create(:workflow_data_quality_report, workflow: workflow, data_quality_report: DataQualityReport.table_count) }
  let!(:workflow_data_quality_report_2) { create(:workflow_data_quality_report, workflow: workflow, data_quality_report: DataQualityReport.table_count) }
  let!(:workflow_data_quality_report_3) { create(:workflow_data_quality_report, workflow: workflow, data_quality_report: DataQualityReport.table_count) }

  let!(:creator) { create(:user) }

  let!(:run) do
    workflow_configuration.runs.create!(creator: creator, execution_plan: workflow_configuration.serialize_and_symbolize)
  end
end

shared_examples 'cheesey workflow dependency graph' do

  let!(:workflow_configuration) { create(:workflow_configuration) }

  let!(:parent_workflow) { workflow_configuration.workflow }

  let!(:child_workflow_1) { create(:workflow) }
  let!(:included_dependency_1) { create(:workflow_dependency, included_workflow: child_workflow_1, including_workflow: parent_workflow) }

  let!(:child_workflow_2) { create(:workflow) }
  let!(:included_dependency_2) { create(:workflow_dependency, included_workflow: child_workflow_2, including_workflow: parent_workflow) }

  let!(:grandchild_workflow_2_1) { create(:workflow) }
  let!(:included_dependency_2_1) { create(:workflow_dependency, included_workflow: grandchild_workflow_2_1, including_workflow: child_workflow_2) }

  let!(:great_grandchild_workflow_2_1_1) { create(:workflow) }
  let!(:included_dependency_2_1_1) { create(:workflow_dependency, included_workflow: great_grandchild_workflow_2_1_1, including_workflow: grandchild_workflow_2_1) }

  let!(:independent_workflow) { create(:workflow) }

end
