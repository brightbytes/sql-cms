# == Schema Information
#
# Table name: workflow_configurations
#
#  id             :integer          not null, primary key
#  workflow_id    :integer          not null
#  s3_region_name :string           not null
#  s3_bucket_name :string           not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  customer_id    :integer
#  s3_file_path   :string
#
# Indexes
#
#  index_unique_workflow_configurations_on_workflow_customer  (workflow_id,customer_id) UNIQUE
#  index_workflow_configurations_on_customer_id               (customer_id)
#
# Foreign Keys
#
#  fk_rails_...  (customer_id => customers.id)
#  fk_rails_...  (workflow_id => workflows.id)
#

describe WorkflowConfiguration do

  describe 'versioned by PaperTrail' do
    it { is_expected.to be_versioned }
  end

  describe 'validations' do
    [:workflow, :s3_region_name, :s3_bucket_name].each do |att|
      it { should validate_presence_of(att) }
    end

    context 'with a WorkflowConfiguration already extant' do
      let!(:subject) { create(:workflow_configuration) }
      it { should validate_uniqueness_of(:workflow).scoped_to(:customer_id) }
    end
  end

  describe 'associations' do
    it { should belong_to(:workflow) }
    it { should belong_to(:customer) }
  end

end
