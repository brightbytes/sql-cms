class WorkflowDependency < ApplicationRecord

  # Validations

  validates :dependent_workflow, :independent_workflow, presence: true

  validates :independent_workflow, uniqueness: { scope: :dependent_workflow_id }

  # Associations

  belongs_to :dependent_workflow, class_name: 'Workflow', inverse_of: :independencies
  belongs_to :independent_workflow, class_name: 'Workflow', inverse_of: :dependencies

end
