FactoryGirl.define do

  factory :data_quality_report do
    sequence(:name) { |n| "Data Quality Report #{n}" }
    sequence(:sql)  { |n| "SELECT COUNT(1) FROM some_lame_table" }
    association :workflow
  end

end
