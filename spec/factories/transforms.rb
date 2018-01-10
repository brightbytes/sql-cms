# == Schema Information
#
# Table name: transforms
#
#  id           :integer          not null, primary key
#  name         :string           not null
#  runner       :string           default("Sql"), not null
#  workflow_id  :integer          not null
#  sql          :text             not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  params       :jsonb
#  s3_file_name :string
#  enabled      :boolean          default(TRUE), not null
#
# Indexes
#
#  index_transforms_on_lowercase_name_and_workflow_id  (lower((name)::text), workflow_id) UNIQUE
#  index_transforms_on_workflow_id                     (workflow_id)
#
# Foreign Keys
#
#  fk_rails_...  (workflow_id => workflows.id)
#

FactoryBot.define do

  factory :transform do
    sequence(:name) { |n| "Transform #{n}" }
    runner 'Sql'
    sequence(:sql)  { |n| "SELECT 1" }
    association :workflow
  end

  factory :transform_dependency do
    association :prerequisite_transform, factory: :transform
    association :postrequisite_transform, factory: :transform
  end

end
