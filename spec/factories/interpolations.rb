# == Schema Information
#
# Table name: interpolations
#
#  id   :integer          not null, primary key
#  name :string           not null
#  slug :string           not null
#  sql  :string           not null
#
# Indexes
#
#  index_interpolations_on_lowercase_name  (lower((name)::text)) UNIQUE
#  index_interpolations_on_lowercase_slug  (lower((slug)::text)) UNIQUE
#

FactoryGirl.define do
  factory :interpolation do
    sequence(:name) { |n| "Interpolation #{n}" }
    sequence(:slug) { |n| "interpolation_slug_#{n}" }
    sql "SELECT 1"
  end

end
