# frozen_string_literal: true
# == Schema Information
#
# Table name: public.data_quality_reports
#
#  id                                 :integer          not null, primary key
#  workflow_id                        :integer          not null
#  name                               :string           not null
#  sql                                :text             not null
#  created_at                         :datetime         not null
#  updated_at                         :datetime         not null
#  params                             :jsonb
#
# Indexes
#
#  index_data_quality_reports_on_lowercase_name                    (lower((name)::text)) UNIQUE
#  index_data_quality_reports_on_workflow_id                       (workflow_id)
#
# Foreign Keys
#
#  fk_rails_...  (workflow_id => workflows.id)
#

FactoryBot.define do

  factory :data_quality_report do
    sequence(:name) { |n| "Data Quality Report #{n}" }
    sequence(:sql)  { |n| "SELECT COUNT(1) FROM :table_name" }
  end

  factory :workflow_data_quality_report do
    association :workflow
    association :data_quality_report
    sequence(:params) { |n| { table_name: "tmp_#{n}" } }
  end

end
