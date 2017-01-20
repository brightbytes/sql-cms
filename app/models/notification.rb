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
#  fk_rails_56d6267752  (workflow_id => workflows.id)
#  fk_rails_b080fb4855  (user_id => users.id)
#

class Notification < ActiveRecord::Base

  # Validations

  validates :user, presence: true

  validates :workflow, presence: true, uniqueness: { scope: :user_id }

  # Associations

  belongs_to :user, inverse_of: :notifications

  belongs_to :workflow, inverse_of: :notifications


end
