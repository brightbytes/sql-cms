FactoryGirl.define do

  factory :run do
    association :workflow
    association :creator, factory: :user
    execution_plan { { bogus: :plan } }
  end

  factory :run_step_log do
    association :run
    step_type "data_quality_report"
    sequence(:step_id)
  end

end
