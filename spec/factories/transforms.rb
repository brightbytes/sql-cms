# == Schema Information
#
# Table name: public.transforms
#
#  id             :integer          not null, primary key
#  name           :string           not null
#  runner         :string           default("Sql"), not null
#  workflow_id    :integer          not null
#  sql            :text             not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  params         :jsonb
#  s3_region_name :string
#  s3_bucket_name :string
#  s3_file_path   :string
#  s3_file_name   :string
#
# Indexes
#
#  index_transforms_on_lowercase_name  (lower((name)::text)) UNIQUE
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
