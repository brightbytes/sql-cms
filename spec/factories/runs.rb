FactoryGirl.define do

  factory :run do
    association :workflow
    association :creator, factory: :user
    execution_plan { { bogus: :plan } }
  end

  factory :step_log do
    association :run
    step { create(:pipeline_transform, pipeline: run.pipeline) }
  end


end
