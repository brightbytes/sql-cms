# == Schema Information
#
# Table name: public.notifications
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
#

# The FK on workflow_configuration_id is actually in the DB ... but, annoyingly, annotate doesn't pick it up
class Notification < ApplicationRecord

  # Validations

  validates :user, presence: true

  validates :workflow_configuration, presence: true, uniqueness: { scope: :user_id }

  # Associations

  belongs_to :user, inverse_of: :notifications

  belongs_to :workflow_configuration, inverse_of: :notifications


end
