FactoryGirl.define do

  factory :data_file do
    sequence(:name) { |n| "Data File #{n}" }
    upload { File.new(Rails.root.join('spec', 'fixtures', 'files', 'test.csv')) }
    association :creator, factory: :user
    association :customer
  end
end
