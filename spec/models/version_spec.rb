require 'spec_helper'

describe PaperTrail::Version, :versioning do
  let(:user) { create(:user) }

  before do
    ::PaperTrail.request.whodunnit = user
    user.update_attributes(first_name: "foobie")
  end
  after { ::PaperTrail.request.whodunnit = nil }

  it "should populate the user_id column by calling .to_i on the whodunnit column" do
    expect(user.versions.last.user_id).to eq user.id
  end
end
