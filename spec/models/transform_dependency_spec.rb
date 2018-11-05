# == Schema Information
#
# Table name: transform_dependencies
#
#  id                         :integer          not null, primary key
#  prerequisite_transform_id  :integer          not null
#  postrequisite_transform_id :integer          not null
#  created_at                 :datetime         not null
#
# Indexes
#
#  index_transform_dependencies_on_prerequisite_transform_id  (prerequisite_transform_id)
#  index_transform_dependencies_on_unique_transform_ids       (postrequisite_transform_id,prerequisite_transform_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (postrequisite_transform_id => transforms.id)
#  fk_rails_...  (prerequisite_transform_id => transforms.id)
#

describe TransformDependency, type: :model do

  describe 'versioned by PaperTrail' do
    it { is_expected.to be_versioned }
  end

  describe 'validations' do
    [:postrequisite_transform, :prerequisite_transform].each do |att|
      it { should validate_presence_of(att) }
    end

    context 'with a notification already extant' do
      let!(:subject) { create(:transform_dependency) }
      it { should validate_uniqueness_of(:prerequisite_transform).scoped_to(:postrequisite_transform_id) }
    end

  end

  describe 'associations' do
    it { should belong_to(:prerequisite_transform) }
    it { should belong_to(:postrequisite_transform) }
  end

  describe 'instance methods' do

  end

end
