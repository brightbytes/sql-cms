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
