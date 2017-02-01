# frozen_string_literal: true
# == Schema Information
#
# Table name: public.data_quality_reports
#
#  id                                 :integer          not null, primary key
#  workflow_id                        :integer          not null
#  name                               :string           not null
#  params                             :jsonb            not null
#  sql                                :text             not null
#  created_at                         :datetime         not null
#  updated_at                         :datetime         not null
#  copied_from_data_quality_report_id :integer
#
# Indexes
#
#  idx_data_quality_reports_on_copied_from_data_quality_report_id  (copied_from_data_quality_report_id)
#  index_data_quality_reports_on_lowercase_name                    (lower((name)::text)) UNIQUE
#  index_data_quality_reports_on_workflow_id                       (workflow_id)
#
# Foreign Keys
#
#  fk_rails_...  (copied_from_data_quality_report_id => data_quality_reports.id)
#  fk_rails_...  (workflow_id => workflows.id)
#

class DataQualityReport < ApplicationRecord

  include Concerns::ParamsHelpers

  auto_normalize

  # Validations

  validates :sql, :workflow, presence: true

  validates :name, presence: true, uniqueness: { case_sensitive: false }

  validate :params_not_null

  def params_not_null
    errors.add(:params, 'may not be null') unless params # {} is #blank?, hence this hair
  end

  # Associations

  belongs_to :workflow, inverse_of: :data_quality_reports

  belongs_to :copied_from_data_quality_report, class_name: 'DataQualityReport', inverse_of: :copied_to_data_quality_reports
  has_many :copied_to_data_quality_reports, class_name: 'DataQualityReport', foreign_key: :copied_from_data_quality_report_id, inverse_of: :copied_from_data_quality_report


end
