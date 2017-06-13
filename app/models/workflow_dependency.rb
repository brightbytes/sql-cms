# == Schema Information
#
# Table name: public.workflow_dependencies
#
#  id                    :integer          not null, primary key
#  included_workflow_id  :integer          not null
#  including_workflow_id :integer          not null
#  created_at            :datetime         not null
#
# Indexes
#
#  index_workflow_dependencies_on_including_workflow_id       (including_workflow_id)
#  index_workflow_depenencies_on_independent_id_dependent_id  (included_workflow_id,including_workflow_id) UNIQUE
#

class WorkflowDependency < ApplicationRecord

  # Validations

  validates :including_workflow, :included_workflow, presence: true

  validates :included_workflow, uniqueness: { scope: :including_workflow_id }

  # Associations

  belongs_to :including_workflow, class_name: 'Workflow', inverse_of: :included_dependencies
  belongs_to :included_workflow, class_name: 'Workflow', inverse_of: :including_dependencies

end
