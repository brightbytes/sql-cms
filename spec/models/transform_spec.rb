# == Schema Information
#
# Table name: transforms
#
#  id                            :integer          not null, primary key
#  name                          :string           not null
#  runner                        :string           not null
#  workflow_id                   :integer          not null
#  sql_params                    :jsonb            not null
#  sql                           :text             not null
#  created_at                    :datetime         not null
#  updated_at                    :datetime         not null
#  transcompiled_source          :text
#  transcompiled_source_language :string
#  data_file_id                  :integer
#  copied_from_transform_id      :integer
#
# Indexes
#
#  index_transforms_on_copied_from_transform_id      (copied_from_transform_id)
#  index_transforms_on_data_file_id                  (data_file_id)
#  index_transforms_on_lowercase_name                (lower((name)::text)) UNIQUE
#  index_transforms_on_workflow_id_and_data_file_id  (workflow_id,data_file_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (copied_from_transform_id => transforms.id)
#  fk_rails_...  (data_file_id => data_files.id)
#  fk_rails_...  (workflow_id => workflows.id)
#

describe Transform do

  describe 'versioned by PaperTrail' do
    it { is_expected.to be_versioned }
  end

  describe "validations" do
    [:name, :runner, :sql, :workflow].each do |att|
      it { should validate_presence_of(att) }
    end

    context "with a transform already extant" do
      let!(:subject) { create(:transform) }
      it { should validate_uniqueness_of(:name).case_insensitive }
      # Doesn't work
      # it { should validate_uniqueness_of(:data_file).scoped_to(:workflow_id).allow_nil }
    end

  end

  describe "callbacks" do

  end

  describe "associations" do
    it { should belong_to(:workflow) }
    it { should belong_to(:data_file) }
    it { should belong_to(:copied_from_transform) }
    it { should have_many(:copied_to_transforms) }

    # it { should have_many(:transform_validations) }
    # it { should have_many(:validations) }
    # it { should have_many(:prerequisite_dependencies) }
    # it { should have_many(:prerequisite_transforms) }
    # it { should have_many(:postrequisite_dependencies) }
    # it { should have_many(:postrequisite_transforms) }
  end
end
