describe CustomerSeeder do

  describe "#seed" do

    it "should idempotently create some users" do
      # Fucking DatabaseCleaner doesn't work
      Customer.delete_all
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
