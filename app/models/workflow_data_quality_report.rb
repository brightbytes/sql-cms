# == Schema Information
#
# Table name: public.workflow_data_quality_reports
#
#  id                     :integer          not null, primary key
#  workflow_id            :integer          not null
#  data_quality_report_id :integer          not null
#  params                 :jsonb            not null
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#
# Indexes
#
#  index_workflow_data_quality_reports_on_data_quality_report_id  (data_quality_report_id)
#  index_workflow_data_quality_reports_on_workflow_id             (workflow_id)
#

class WorkflowDataQualityReport < ApplicationRecord

  include Concerns::ParamsHelpers

  # Validations

  # Note that here, params can never be NULL/empty, unlike other JSONB columns.
  validates :workflow, :data_quality_report, :params, presence: true

  # Associations

  with_options(inverse_of: :workflow_data_quality_reports) do |o|
    o.belongs_to :workflow
    o.belongs_to :data_quality_report
  end

  # Instance Methods

  delegate :name, :sql, to: :data_quality_report

  # FIXME - MAKE THE NAME INTERPOLATABLE
  def name
    "Data Quality Report '#{data_quality_report.name}' for Workflow '#{workflow.name}'"
  end

end
