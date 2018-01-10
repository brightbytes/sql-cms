# == Schema Information
#
# Table name: runs
#
#  id                        :integer          not null, primary key
#  creator_id                :integer          not null
#  execution_plan            :jsonb            not null
#  status                    :string           default("unstarted"), not null
#  notification_status       :string           default("unsent"), not null
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  schema_name               :string
#  workflow_configuration_id :integer          not null
#  immutable                 :boolean          default(FALSE), not null
#  finished_at               :datetime
#
# Indexes
#
#  index_runs_on_creator_id                 (creator_id)
#  index_runs_on_workflow_configuration_id  (workflow_configuration_id)
#
# Foreign Keys
#
#  fk_rails_...  (creator_id => users.id)
#  fk_rails_...  (workflow_configuration_id => workflow_configurations.id)
#

FactoryBot.define do

  factory :run do
    association :workflow_configuration
    association :creator, factory: :user
    execution_plan { { bogus: :plan } }
  end

  factory :run_step_log do
    association :run
    step_type "workflow_data_quality_report"
    sequence(:step_id)
  end

end
