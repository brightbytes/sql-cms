# == Schema Information
#
# Table name: notifications
#
#  id                        :integer          not null, primary key
#  user_id                   :integer          not null
#  created_at                :datetime         not null
#  workflow_configuration_id :integer          not null
#
# Indexes
#
#  index_notifications_on_user_id                                (user_id)
#  index_notifications_on_workflow_configuration_id_and_user_id  (workflow_configuration_id,user_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#  fk_rails_...  (workflow_configuration_id => workflow_configurations.id)
#

FactoryBot.define do
  factory :notification do
    association :user
    association :workflow_configuration
  end
end
