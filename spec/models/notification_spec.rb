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

describe Notification do

  describe 'versioned by PaperTrail' do
    it { is_expected.to be_versioned }
  end

  describe 'validations' do
    [:user, :workflow_configuration].each do |att|
      it { should validate_presence_of(att) }
    end

    context 'with a notification already extant' do
      let!(:subject) { create(:notification) }
      it { should validate_uniqueness_of(:workflow_configuration).scoped_to(:user_id) }
    end

  end

  describe 'associations' do
    it { should belong_to(:workflow_configuration) }
    it { should belong_to(:user) }
  end

end
