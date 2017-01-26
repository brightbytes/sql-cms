# == Schema Information
#
# Table name: transforms
#
#  id                            :integer          not null, primary key
#  name                          :string           not null
#  transform_type                :string           not null
#  workflow_id                   :integer          not null
#  params                    :jsonb            not null
#  sql                           :text             not null
#  created_at                    :datetime         not null
#  updated_at                    :datetime         not null
#  transcompiled_source          :text
#  transcompiled_source_language :string
#  data_file_id                  :integer
#  copied_from_transform_id      :integer
#
# Indexes
#
#  index_transforms_on_copied_from_transform_id      (copied_from_transform_id)
#  index_transforms_on_data_file_id                  (data_file_id)
#  index_transforms_on_lowercase_name                (lower((name)::text)) UNIQUE
#  index_transforms_on_workflow_id_and_data_file_id  (workflow_id,data_file_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (copied_from_transform_id => transforms.id)
#  fk_rails_...  (data_file_id => data_files.id)
#  fk_rails_...  (workflow_id => workflows.id)
#

FactoryGirl.define do

  factory :transform do
    sequence(:name) { |n| "Transform #{n}" }
    runner 'CopyFrom'
    sequence(:sql)  { |n| "COPY tmp_#{n} (id, stringy) FROM STDIN WITH CSV HEADER" }
    association :workflow
  end

  factory :transform_dependency do
    association :prerequisite_transform, factory: :transform
    association :postrequisite_transform, factory: :transform
  end

end
