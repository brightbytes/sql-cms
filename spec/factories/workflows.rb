# == Schema Information
#
# Table name: public.workflows
#
#  id             :integer          not null, primary key
#  name           :string           not null
#  slug           :string           not null
#  customer_id    :integer
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  shared         :boolean          default(FALSE), not null
#  s3_region_name :string           not null
#  s3_bucket_name :string           not null
#
# Indexes
#
#  index_workflows_on_customer_id     (customer_id)
#  index_workflows_on_lowercase_name  (lower((name)::text)) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (customer_id => customers.id)
#

FactoryGirl.define do
  factory :workflow do
    sequence(:name) { |n| "Workflow #{n}" }
    association :customer
    s3_bucket_name "my-favorite-bucket"
  end

  factory :shared_workflow, parent: :workflow do
    shared true
    customer nil
  end

  factory :workflow_dependency do
    association :included_workflow, factory: :shared_workflow
    association :including_workflow, factory: :workflow
  end
end
