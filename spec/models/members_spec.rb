require 'spec_helper'

describe Member do
  describe "Associations" do
    it { is_expected.to belong_to(:user) }
  end

  describe "Validation" do
    subject { Member.new(access_level: Member::GUEST) }

    it { is_expected.to validate_presence_of(:user) }
    it { is_expected.to validate_presence_of(:source) }
    it { is_expected.to validate_inclusion_of(:access_level).in_array(Gitlab::Access.values) }
  end

  describe "Delegate methods" do
    it { is_expected.to respond_to(:user_name) }
    it { is_expected.to respond_to(:user_email) }
  end
end
