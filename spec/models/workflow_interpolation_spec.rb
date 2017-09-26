# == Schema Information
#
# Table name: workflow_interpolations
#
#  id          :integer          not null, primary key
#  workflow_id :integer          not null
#  name        :string           not null
#  slug        :string           not null
#  sql         :string           not null
#
# Indexes
#
#  index_workflow_interpolations_on_lowercase_name_and_workflow_id  (lower((name)::text), workflow_id) UNIQUE
#  index_workflow_interpolations_on_lowercase_slug_and_workflow_id  (lower((slug)::text), workflow_id) UNIQUE
#  index_workflow_interpolations_on_workflow_id                     (workflow_id)
#
# Foreign Keys
#
#  fk_rails_...  (workflow_id => workflows.id)
#

describe WorkflowInterpolation do

  describe "validations" do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:slug) }
    it { should validate_presence_of(:sql) }

    context "with a Customer already extant" do
      let!(:subject) { create(:workflow_interpolation) }
      # These interfere with one another.
      # it { should validate_uniqueness_of(:name).case_insensitive.scoped_to(:workflow_id) }
      # it { should validate_uniqueness_of(:slug).case_insensitive.scoped_to(:workflow_id) }
    end
  end

  describe "associations" do
    it { should belong_to(:workflow) }
  end


end
