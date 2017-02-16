# == Schema Information
#
# Table name: public.data_files
#
#  id             :integer          not null, primary key
#  name           :string           not null
#  metadata       :jsonb            not null
#  customer_id    :integer          not null
#  s3_bucket_name :string           not null
#  s3_file_name   :string           not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  deleted_at     :datetime
#
# Indexes
#
#  index_data_files_on_customer_id     (customer_id)
#  index_data_files_on_lowercase_name  (lower((name)::text)) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (customer_id => customers.id)
#

FactoryGirl.define do

  factory :data_file do
    sequence(:name) { |n| "Data File #{n}" }
    s3_bucket_name "bb-pipeline-sandbox-rawdata"
    s3_file_path "ca_some_sis/v_2_201610041757_full/calendars_2015.tsv"
    s3_file_name "part_0000.tsv"
    association :workflow
  end
end
