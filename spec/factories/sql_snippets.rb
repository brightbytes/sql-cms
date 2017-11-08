# == Schema Information
#
# Table name: sql_snippets
#
#  id         :integer          not null, primary key
#  name       :string           not null
#  slug       :string           not null
#  sql        :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_interpolations_on_lowercase_name  (lower((name)::text)) UNIQUE
#  index_interpolations_on_lowercase_slug  (lower((slug)::text)) UNIQUE
#

FactoryGirl.define do
  factory :sql_snippet do
    sequence(:name) { |n| "SQL Snippet #{n}" }
    sequence(:slug) { |n| "sql_snippet_slug_#{n}" }
    sql "SELECT 1"
  end

end
