describe ExecutionPlan do

  context "A Workflow with included Workflows with Transforms and DataQualityReports, some of which have included Workflows with Transforms and DataQualityReports" do

    let!(:workflow_configuration) { create(:workflow_configuration) }

    let!(:parent_workflow) { workflow_configuration.workflow }
    let!(:parent_prereq_transform) { create(:transform, workflow: parent_workflow) }
    let!(:parent_postreq_transform) { create(:transform, workflow: parent_workflow) }
    let!(:parent_transform_dependency) { create(:transform_dependency, prerequisite_transform: parent_prereq_transform, postrequisite_transform: parent_postreq_transform) }
    let!(:parent_workflow_data_quality_report) { create(:workflow_data_quality_report, workflow: parent_workflow) }

    let!(:child_workflow_1) { create(:workflow) }
    let!(:included_dependency_1) { create(:workflow_dependency, included_workflow: child_workflow_1, including_workflow: parent_workflow) }
    let!(:child_prereq_transform_1) { create(:transform, workflow: child_workflow_1) }
    let!(:child_postreq_transform_1) { create(:transform, workflow: child_workflow_1) }
    let!(:child_transform_dependency_1) { create(:transform_dependency, prerequisite_transform: child_prereq_transform_1, postrequisite_transform: child_postreq_transform_1) }
    let!(:child_workflow_data_quality_report_1) { create(:workflow_data_quality_report, workflow: child_workflow_1) }

    let!(:grandchild_workflow_1_1) { create(:workflow) }
    let!(:included_dependency_1_1) { create(:workflow_dependency, included_workflow: grandchild_workflow_1_1, including_workflow: child_workflow_1) }
    let!(:grandchild_prereq_transform_1_1) { create(:transform, workflow: grandchild_workflow_1_1) }
    let!(:grandchild_postreq_transform_1_1) { create(:transform, workflow: grandchild_workflow_1_1) }
    let!(:grandchild_transform_dependency_1_1) { create(:transform_dependency, prerequisite_transform: grandchild_prereq_transform_1_1, postrequisite_transform: grandchild_postreq_transform_1_1) }
    let!(:grandchild_workflow_data_quality_report_1_1) { create(:workflow_data_quality_report, workflow: grandchild_workflow_1_1) }

    let!(:child_workflow_2) { create(:workflow) }
    let!(:included_dependency_2) { create(:workflow_dependency, included_workflow: child_workflow_2, including_workflow: parent_workflow) }
    let!(:child_prereq_transform_2) { create(:transform, workflow: child_workflow_2) }
    let!(:child_postreq_transform_2) { create(:transform, workflow: child_workflow_2) }
    let!(:child_transform_dependency_2) { create(:transform_dependency, prerequisite_transform: child_prereq_transform_2, postrequisite_transform: child_postreq_transform_2) }
    let!(:child_workflow_data_quality_report_2) { create(:workflow_data_quality_report, workflow: child_workflow_2) }

    let!(:grandchild_workflow_2_1) { create(:workflow) }
    let!(:included_dependency_2_1) { create(:workflow_dependency, included_workflow: grandchild_workflow_2_1, including_workflow: child_workflow_2) }
    let!(:grandchild_prereq_transform_2_1) { create(:transform, workflow: grandchild_workflow_2_1) }
    let!(:grandchild_postreq_transform_2_1) { create(:transform, workflow: grandchild_workflow_2_1) }
    let!(:grandchild_transform_dependency_2_1) { create(:transform_dependency, prerequisite_transform: grandchild_prereq_transform_2_1, postrequisite_transform: grandchild_postreq_transform_2_1) }
    let!(:grandchild_workflow_data_quality_report_2_1) { create(:workflow_data_quality_report, workflow: grandchild_workflow_2_1) }

    let!(:great_grandchild_workflow_2_1_1) { create(:workflow) }
    let!(:included_dependency_2_1_1) { create(:workflow_dependency, included_workflow: great_grandchild_workflow_2_1_1, including_workflow: grandchild_workflow_2_1) }
    let!(:great_grandchild_prereq_transform_2_1_1) { create(:transform, workflow: great_grandchild_workflow_2_1_1) }
    let!(:great_grandchild_postreq_transform_2_1_1) { create(:transform, workflow: great_grandchild_workflow_2_1_1) }
    let!(:great_grandchild_transform_dependency_2_1_1) { create(:transform_dependency, prerequisite_transform: great_grandchild_prereq_transform_2_1_1, postrequisite_transform: great_grandchild_postreq_transform_2_1_1) }
    let!(:great_grandchild_workflow_data_quality_report_2_1_1) { create(:workflow_data_quality_report, workflow: great_grandchild_workflow_2_1_1) }

    it "should produce the expected ExecutionPlan" do
      execution_plan = ExecutionPlan.create(workflow_configuration)

      dqr_ids = [parent_workflow_data_quality_report, child_workflow_data_quality_report_1, grandchild_workflow_data_quality_report_1_1, child_workflow_data_quality_report_2, grandchild_workflow_data_quality_report_2_1, great_grandchild_workflow_data_quality_report_2_1_1].map(&:id)
      expect(execution_plan.workflow_data_quality_report_ids).to match_array(dqr_ids)

      expect(execution_plan.transform_group_transform_ids(0)).to match_array([grandchild_prereq_transform_1_1, great_grandchild_prereq_transform_2_1_1].map(&:id))
      expect(execution_plan.transform_group_transform_ids(1)).to match_array([grandchild_postreq_transform_1_1, great_grandchild_postreq_transform_2_1_1].map(&:id))

      expect(execution_plan.transform_group_transform_ids(2)).to match_array([child_prereq_transform_1, grandchild_prereq_transform_2_1].map(&:id))
      expect(execution_plan.transform_group_transform_ids(3)).to match_array([child_postreq_transform_1, grandchild_postreq_transform_2_1].map(&:id))

      expect(execution_plan.transform_group_transform_ids(4)).to match_array([child_prereq_transform_2].map(&:id))
      expect(execution_plan.transform_group_transform_ids(5)).to match_array([child_postreq_transform_2].map(&:id))

      expect(execution_plan.transform_group_transform_ids(6)).to match_array([parent_prereq_transform].map(&:id))
      expect(execution_plan.transform_group_transform_ids(7)).to match_array([parent_postreq_transform].map(&:id))
    end

  end

end
