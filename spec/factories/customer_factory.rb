
FactoryGirl.define do

  factory :customer do
    sequence(:name) { FFaker::Name.name }
    # slug will be auto-set
  end

end
