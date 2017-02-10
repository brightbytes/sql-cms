# frozen_string_literal: true
describe ValidationSeeder do

  describe "#seed" do

    it "should idempotently create some validations" do
      expect(Validation.count).to eq(0)
      expect { ValidationSeeder.seed }.to_not raise_error
      count = Validation.count
      expect(count).to be > 0
      expect { ValidationSeeder.seed }.to_not raise_error
      new_count = Validation.count
      expect(new_count).to eq(count)
    end
  end


end
