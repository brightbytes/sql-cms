# frozen_string_literal: true
# == Schema Information
#
# Table name: public.data_quality_reports
#
#  id         :integer          not null, primary key
#  name       :string           not null
#  sql        :text             not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  immutable  :boolean          default(FALSE)
#
# Indexes
#
#  index_data_quality_reports_on_lowercase_name  (lower((name)::text)) UNIQUE
#

class DataQualityReport < ApplicationRecord

  auto_normalize

  # Validations

  validates :sql, presence: true

  validates :name, presence: true, uniqueness: { case_sensitive: false }

  # Callbacks

  include Concerns::ImmutableCallbacks
  immutable :update, :destroy

  # Associations

  has_many :workflow_data_quality_reports, inverse_of: :data_quality_report, dependent: :delete_all
  has_many :workflows, through: :workflow_data_quality_reports

  # Instance Methods

  def usage_count
    workflow_data_quality_reports.count
  end

  # Class Methods

  class << self

    def table_count
      @table_count ||= where(name: 'Table :table_name Count').first_or_create!(
        immutable: true,
        sql: 'SELECT COUNT(1) FROM :table_name'
      )
    end

    def column_value_distribution
      @column_value_distribution ||= where(name: 'Column :table_name.:column_name Value Distribution').first_or_create!(
        immutable: true,
        sql: "SELECT :column_name, COUNT(1) AS count FROM :table_name GROUP BY :column_name ORDER BY count DESC"
      )
    end

    def column_non_unique_value_distribution
      @column_non_unique_value_distribution ||= where(name: 'Column :table_name.:column_name Non-Unique Value Distribution').first_or_create!(
        immutable: true,
        sql: "SELECT :column_name, COUNT(1) AS count FROM :table_name GROUP BY :column_name HAVING COUNT(:column_name) > 1 ORDER BY count DESC"
      )
    end

    def flush_cache
      @table_count = @column_value_distribution = @column_non_unique_value_distribution = nil
    end

  end
end
