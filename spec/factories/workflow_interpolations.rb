# == Schema Information
#
# Table name: workflow_interpolations
#
#  id          :integer          not null, primary key
#  workflow_id :integer          not null
#  name        :string           not null
#  slug        :string           not null
#  sql         :string           not null
#
# Indexes
#
#  index_workflow_interpolations_on_lowercase_name_and_workflow_id  (lower((name)::text), workflow_id) UNIQUE
#  index_workflow_interpolations_on_lowercase_slug_and_workflow_id  (lower((slug)::text), workflow_id) UNIQUE
#  index_workflow_interpolations_on_workflow_id                     (workflow_id)
#
# Foreign Keys
#
#  fk_rails_...  (workflow_id => workflows.id)
#

FactoryGirl.define do
  factory :workflow_interpolation do
    sequence(:name) { |n| "Workflow Interpolation #{n}" }
    sequence(:slug) { |n| "slug_#{n}" }
    sql "SELECT 1"
    association :workflow
  end

end
