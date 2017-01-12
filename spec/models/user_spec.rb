# == Schema Information
#
# Table name: users
#
#  id                     :integer          not null, primary key
#  email                  :string           default(""), not null
#  encrypted_password     :string           default(""), not null
#  reset_password_token   :string
#  reset_password_sent_at :datetime
#  remember_created_at    :datetime
#  sign_in_count          :integer          default(0), not null
#  current_sign_in_at     :datetime
#  last_sign_in_at        :datetime
#  current_sign_in_ip     :inet
#  last_sign_in_ip        :inet
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  deleted_at             :datetime
#  first_name             :string           not null
#  last_name              :string           not null
#
# Indexes
#
#  index_users_on_email                 (email) UNIQUE
#  index_users_on_reset_password_token  (reset_password_token) UNIQUE
#

describe User do

  let!(:user) { create(:user) }

  describe "validations" do
    [:email, :first_name, :last_name].each do |att|
      it { should validate_presence_of(att) }
    end

    context "with a user already extant" do
      let!(:subject) { user }
      it { should validate_uniqueness_of(:email).case_insensitive }
    end

    it "should accept valid email addresses" do
      %w[foo@bar.baz foo_a@bar.baz foo.bar@baz.com foo+bar@baz.com FoO@BaR.com].each do |valid_email|
        user.email = valid_email
        expect(user).to be_valid
      end
    end

    it "should reject invalid email addresses" do
      %w[foo@bar,com user.com @foo.com user@user@com user@.com user@user.].each do |invalid_email|
        user.email = invalid_email
        expect(user).to_not be_valid
      end
    end

    it "should not allow email addresses with semicolons in them (Devise's piece-of-shit email address validator does)" do
      expect(build(:user, email: "foo;bar@nowhere.com")).to_not be_valid
    end

  end

  describe "instance methods" do

    it "should have a #full_name method that concats the first and last names" do
      expect(user.full_name).to eq("#{user.first_name} #{user.last_name}".squish)
    end

  end

end
