# == Schema Information
#
# Table name: public.notifications
#
#  id          :integer          not null, primary key
#  user_id     :integer          not null
#  workflow_id :integer          not null
#  created_at  :datetime         not null
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

describe Notification do

  describe 'versioned by PaperTrail' do
    it { is_expected.to be_versioned }
  end

  describe 'validations' do
    [:user, :workflow].each do |att|
      it { should validate_presence_of(att) }
    end

    context 'with a notification already extant' do
      let!(:subject) { create(:notification) }
      it { should validate_uniqueness_of(:workflow).scoped_to(:user_id) }
    end

  end

  describe 'associations' do
    it { should belong_to(:workflow) }
    it { should belong_to(:user) }
  end

  describe 'instance methods' do

  end

end
