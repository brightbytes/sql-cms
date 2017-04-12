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
# Foreign Keys
#
#  fk_rails_...  (data_quality_report_id => data_quality_reports.id)
#  fk_rails_...  (workflow_id => workflows.id)
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

  def to_s
    interpolated_name
  end

  alias_method :display_name, :to_s

end
