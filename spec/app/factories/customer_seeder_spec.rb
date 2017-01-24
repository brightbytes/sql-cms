# frozen_string_literal: true
describe CustomerSeeder do

  describe "#seed" do

    it "should idempotently create some users" do
      expect(Customer.count).to eq(0)
      expect { CustomerSeeder.seed }.to_not raise_error
      count = Customer.count
      expect(count).to be > 0
      expect { CustomerSeeder.seed }.to_not raise_error
      new_count = Customer.count
      expect(new_count).to eq(count)
    end
  end


end
