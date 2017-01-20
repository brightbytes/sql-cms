FactoryGirl.define do
  factory :notification do
    association :user
    association :workflow
  end
end
