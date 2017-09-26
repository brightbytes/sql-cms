FactoryGirl.define do
  factory :workflow_interpolation do
    sequence(:name) { |n| "Workflow Interpolation #{n}" }
    sql "SELECT 1"
    association :workflow
  end

end
