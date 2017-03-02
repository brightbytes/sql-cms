# frozen_string_literal: true
# == Schema Information
#
# Table name: public.data_quality_reports
#
#  id          :integer          not null, primary key
#  workflow_id :integer          not null
#  name        :string           not null
#  sql         :text             not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  params      :jsonb
#
# Indexes
#
#  index_data_quality_reports_on_lowercase_name  (lower((name)::text)) UNIQUE
#  index_data_quality_reports_on_workflow_id     (workflow_id)
#
# Foreign Keys
#
#  fk_rails_...  (workflow_id => workflows.id)
#

class DataQualityReport < ApplicationRecord

  include Concerns::ParamsHelpers

  auto_normalize

  # Validations

  validates :sql, :workflow, presence: true

  validates :name, presence: true, uniqueness: { case_sensitive: false }

  # Callbacks

  before_validation :maybe_generate_default_sql

  DEFAULT_TABLE_COUNT_SQL = "SELECT COUNT(1) FROM :table_name"

  def maybe_generate_default_sql
    self.sql = DEFAULT_TABLE_COUNT_SQL if sql.blank?
  end

  # Associations

  belongs_to :workflow, inverse_of: :data_quality_reports

  has_one :customer, through: :workflow


end
