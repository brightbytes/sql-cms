# == Schema Information
#
# Table name: notifications
#
#  id          :integer          not null, primary key
#  user_id     :integer          not null
#  workflow_id :integer          not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_notifications_on_user_id                  (user_id)
#  index_notifications_on_workflow_id_and_user_id  (workflow_id,user_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#  fk_rails_...  (workflow_id => workflows.id)
#

FactoryGirl.define do
  factory :notification do
    association :user
    association :workflow
  end
end
