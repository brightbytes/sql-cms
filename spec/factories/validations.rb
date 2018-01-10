# == Schema Information
#
# Table name: validations
#
#  id         :integer          not null, primary key
#  name       :string           not null
#  immutable  :boolean          default(FALSE), not null
#  sql        :text             not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_validations_on_lowercase_name  (lower((name)::text)) UNIQUE
#


FactoryBot.define do

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
