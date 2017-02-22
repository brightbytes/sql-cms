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


FactoryGirl.define do

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

  factory :copy_from_transform, parent: :transform do
    runner 'CopyFrom'
    sequence(:sql)  { |n| "COPY foo (bar, dude) FROM STDIN" }
    s3_bucket_name "bb-pipeline-sandbox-rawdata"
    s3_file_path "ca_some_sis/v_2_201610041757_full/calendars_2015.tsv"
    s3_file_name "part_0000.tsv"
  end

  factory :copy_to_transform, parent: :transform do
    runner 'CopyTo'
    sequence(:sql)  { |n| "COPY (SELECT 1) TO STDOUT" }
    s3_bucket_name "dpl-cms"
    s3_file_path "whatever/path"
    s3_file_name "some.csv"
  end

end
