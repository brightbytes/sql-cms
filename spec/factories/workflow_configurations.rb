# == Schema Information
#
# Table name: workflow_configurations
#
#  id             :integer          not null, primary key
#  workflow_id    :integer          not null
#  s3_region_name :string           not null
#  s3_bucket_name :string           not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  customer_id    :integer
#  s3_file_path   :string
#
# Indexes
#
#  index_unique_workflow_configurations_on_workflow_customer  (workflow_id,customer_id) UNIQUE
#  index_workflow_configurations_on_customer_id               (customer_id)
#
# Foreign Keys
#
#  fk_rails_...  (customer_id => customers.id)
#  fk_rails_...  (workflow_id => workflows.id)
#

FactoryGirl.define do
  factory :workflow_configuration do
    association :workflow
    s3_bucket_name "my-favorite-bucket"
  end
end
