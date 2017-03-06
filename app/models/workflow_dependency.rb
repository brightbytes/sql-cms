# == Schema Information
#
# Table name: workflow_dependencies
#
#  id                      :integer          not null, primary key
#  independent_workflow_id :integer          not null
#  dependent_workflow_id   :integer          not null
#  created_at              :datetime         not null
#
# Indexes
#
#  index_workflow_dependencies_on_dependent_workflow_id       (dependent_workflow_id)
#  index_workflow_depenencies_on_independent_id_dependent_id  (independent_workflow_id,dependent_workflow_id) UNIQUE
#

class WorkflowDependency < ApplicationRecord

  # Validations

  validates :dependent_workflow, :independent_workflow, presence: true

  validates :independent_workflow, uniqueness: { scope: :dependent_workflow_id }

  validate :independent_workflow_is_shared, if: :independent_workflow_id?

  def independent_workflow_is_shared
    errors.add(:independent_workflow, "must be a Shared Workflow") unless independent_workflow.shared?
  end

  validate :dependent_workflow_is_unshared, if: :dependent_workflow_id?

  # We could allow recursive composition of shared workflows, but it's not worth the coding headache at this point.  Revisit if it ever seems pertinent.
  def dependent_workflow_is_unshared
    # The &. is for the idiotic `validate_presence_of` spec to pass
    errors.add(:dependent_workflow, "must be an Unshared Workflow") if dependent_workflow&.shared?
  end

  # Associations

  belongs_to :dependent_workflow, class_name: 'Workflow', inverse_of: :independencies
  belongs_to :independent_workflow, class_name: 'Workflow', inverse_of: :dependencies

end
