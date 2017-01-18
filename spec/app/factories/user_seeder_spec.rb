describe UserSeeder do

  describe "#seed" do

    it "should idempotently create some users" do
      # Fucking DatabaseCleaner doesn't work
      User.delete_all
      expect(User.count).to eq(0)
      expect { UserSeeder.seed }.to_not raise_error
      count = User.count
      expect(count).to be > 0
      expect { UserSeeder.seed }.to_not raise_error
      new_count = User.count
      expect(new_count).to eq(count)
    end
  end


end
