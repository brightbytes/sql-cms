# == Schema Information
#
# Table name: workflows
#
#  id         :integer          not null, primary key
#  name       :string           not null
#  slug       :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  params     :jsonb
#
# Indexes
#
#  index_workflows_on_lowercase_name  (lower((name)::text)) UNIQUE
#  index_workflows_on_lowercase_slug  (lower((slug)::text)) UNIQUE
#

FactoryBot.define do
  factory :workflow do
    sequence(:name) { |n| "Workflow #{n}" }
  end

  factory :workflow_dependency do
    association :included_workflow, factory: :workflow
    association :including_workflow, factory: :workflow
  end
end
