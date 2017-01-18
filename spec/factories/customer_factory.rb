
FactoryGirl.define do

  factory :customer do
    sequence(:name) { FFaker::Name.name }
    # slug will be auto-set
  end

end

# == Schema Information
#
# Table name: customers
#
#  id         :integer          not null, primary key
#  name       :string           not null
#  slug       :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  deleted_at :datetime
#
# Indexes
#
#  index_customers_on_lowercase_name  (lower((name)::text)) UNIQUE
#  index_customers_on_lowercase_slug  (lower((slug)::text)) UNIQUE
#
