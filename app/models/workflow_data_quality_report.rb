# == Schema Information
#
# Table name: public.workflow_data_quality_reports
#
#  id                     :integer          not null, primary key
#  workflow_id            :integer          not null
#  data_quality_report_id :integer          not null
#  params                 :jsonb
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#
# Indexes
#
#  index_workflow_data_quality_reports_on_data_quality_report_id  (data_quality_report_id)
#  index_workflow_data_quality_reports_on_workflow_id             (workflow_id)
#
# Foreign Keys
#
#  fk_rails_...  (data_quality_report_id => data_quality_reports.id)
#  fk_rails_...  (workflow_id => workflows.id)
#

class WorkflowDataQualityReport < ApplicationRecord

  include Concerns::ParamsHelpers
  include Concerns::InterpolationHelpers

  # Validations

  validates :workflow, :data_quality_report, presence: true

  # Associations

  with_options(inverse_of: :workflow_data_quality_reports) do |o|
    o.belongs_to :workflow
    o.belongs_to :data_quality_report
  end

  # Instance Methods

  delegate :name, :sql, to: :data_quality_report

  def params
    # This allows reuse of, e.g., :table_name from the associated Workflow's #params
    (workflow&.params || {}).merge(super || {})
  end

  def workflow_params_yaml
    workflow&.params_yaml
  end

end
