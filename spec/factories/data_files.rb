# == Schema Information
#
# Table name: data_files
#
#  id                  :integer          not null, primary key
#  name                :string           not null
#  metadata            :jsonb            not null
#  customer_id         :integer          not null
#  upload_file_name    :string           not null
#  upload_content_type :string           not null
#  upload_file_size    :integer          not null
#  upload_updated_at   :datetime         not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  deleted_at          :datetime
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
    upload { File.new(Rails.root.join('spec', 'fixtures', 'files', 'test.csv')) }
    association :customer
  end
end
