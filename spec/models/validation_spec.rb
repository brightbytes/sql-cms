# frozen_string_literal: true
# == Schema Information
#
# Table name: public.validations
#
#  id         :integer          not null, primary key
#  name       :string           not null
#  immutable  :boolean          default(FALSE), not null
#  sql        :text             not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

describe Validation do

  describe 'versioned by PaperTrail' do
    it { is_expected.to be_versioned }
  end

  describe "validations" do
    [:name, :sql].each do |att|
      it { should validate_presence_of(att) }
    end

    context "with a validation already extant" do
      let!(:subject) { create(:validation) }
      it { should validate_uniqueness_of(:name).case_insensitive }
    end

  end

  describe "callbacks" do
    it "should be immutable when flagged as such" do
      validation = create(:validation)
      expect(validation.immutable?).to eq(false)
      validation.update_attribute(:immutable, true)
      expect { validation.destroy }.to raise_error("You may not destroy an immutable Validation")
      expect { validation.delete }.to raise_error("You may not bypass callbacks to delete a Class.")
      expect { validation.update_attribute(:sql, "/* Blah */") }.to raise_error("You may not update an immutable Validation")
      expect { validation.update_attributes(sql: "/* Blah */") }.to raise_error("You may not update an immutable Validation")
      expect { validation.update_column(:sql, "/* Blah */") }.to raise_error("You may not bypass callbacks to update a Class.")
    end

    it "should prevent bulk-updates" do
      expect { Validation.delete_all }.to raise_error("You may not bypass callbacks delete all the Validation that exist, since some may be inviolate.")
      expect { Validation.update_all(sql: "/* Blah */") }.to raise_error("You may not bypass callbacks to update all the Validation that exist, since some may be inviolate.")
    end
  end

  describe "associations" do
    it { should have_many(:transform_validations) }
    it { should have_many(:transforms) }
  end
end
