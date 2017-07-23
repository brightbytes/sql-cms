
FactoryGirl.define do

  factory :validation do
    sequence(:name) { |n| "Validation #{n}" }
    sequence(:sql) { |n| "SELECT #{n}" }
  end

  # TransformValidations

  factory :transform_validation do
    association :transform
    association :validation
    sequence(:params) { |n| { column_name: :stringy, table_name: "tmp_#{n}" } }
  end
end
