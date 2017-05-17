# frozen_string_literal: true
# == Schema Information
#
# Table name: public.transform_validations
#
#  id            :integer          not null, primary key
#  transform_id  :integer          not null
#  validation_id :integer          not null
#  params        :jsonb            not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
# Indexes
#
#  index_transform_validations_on_transform_id   (transform_id)
#  index_transform_validations_on_validation_id  (validation_id)
#
# Foreign Keys
#
#  fk_rails_...  (transform_id => transforms.id)
#  fk_rails_...  (validation_id => validations.id)
#

describe TransformValidation do

  describe 'versioned by PaperTrail' do
    it { is_expected.to be_versioned }
  end

  describe "validations" do
    [:transform, :params, :validation].each do |att|
      it { should validate_presence_of(att) }
    end
  end

  describe "associations" do
    it { should belong_to(:transform) }
    it { should belong_to(:validation) }
  end

  describe "instance methods" do

    context "#params" do
      let!(:subject) { build(:transform_validation) }
      include_examples 'yaml helper methods'

      it "should reverse merge the Transform params" do
        t_params = { 'foo' => 'bar' }
        t = create(:transform, params: t_params)

        tv_params = { 'blah' => 'whatever' }
        tv = build(:transform_validation, transform: t, params: tv_params)
        expect(tv.params).to eq(t_params.reverse_merge(tv_params))
        # expect(tv.params_yaml).to eq(t_params.merge(tv_params).to_yaml)

        tv_params = {}
        tv = build(:transform_validation, transform: t, params: tv_params)
        expect(tv.params).to eq(t_params.reverse_merge(tv_params))
        # expect(tv.params_yaml).to eq(t_params.merge(tv_params).to_yaml)
      end
    end

  end
end
