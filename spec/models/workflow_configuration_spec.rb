# == Schema Information
#
# Table name: workflow_configurations
#
#  id                       :integer          not null, primary key
#  workflow_id              :integer          not null
#  s3_region_name           :string           not null
#  s3_bucket_name           :string           not null
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  customer_id              :integer
#  s3_file_path             :string
#  redshift                 :boolean          default(FALSE), not null
#  export_transform_options :text
#  import_transform_options :text
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

describe WorkflowConfiguration, type: :model do

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

    it { should have_many(:runs) }

    it { should have_many(:notifications) }
    it { should have_many(:notified_users).through(:notifications).source(:user) }
  end

  describe 'instance methods' do
    context "#rfc_email_addresses_to_notify" do
      it "should simply return a list of rfc-compliant notified_user emails" do
        notification_1 = create(:notification)
        workflow_configuration = notification_1.workflow_configuration
        notification_2 = create(:notification, workflow_configuration: workflow_configuration)
        notification_3 = create(:notification, workflow_configuration: workflow_configuration)
        ignored_notification = create(:notification)
        expect(Set.new(workflow_configuration.rfc_email_addresses_to_notify)).to eq(Set.new([notification_1, notification_2, notification_3].map(&:user).map(&:rfc_email_address)))
      end
    end
  end

end
