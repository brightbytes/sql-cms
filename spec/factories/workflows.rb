# == Schema Information
#
# Table name: workflows
#
#  id                      :integer          not null, primary key
#  name                    :string           not null
#  customer_id             :integer          not null
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  copied_from_workflow_id :integer
#
# Indexes
#
#  index_workflows_on_copied_from_workflow_id     (copied_from_workflow_id)
#  index_workflows_on_customer_id                 (customer_id)
#  index_workflows_on_lowercase_name              (lower((name)::text)) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (copied_from_workflow_id => workflows.id)
#  fk_rails_...  (customer_id => customers.id)
#
FactoryGirl.define do
  factory :workflow do
    sequence(:name) { |n| "Workflow #{n}" }
    association :customer
  end
end
