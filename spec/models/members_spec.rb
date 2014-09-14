require 'spec_helper'

describe Member do
  describe "Associations" do
    it { should belong_to(:user) }
  end

  describe "Validation" do
    subject { Member.new(access_level: Member::GUEST) }

    it { should validate_presence_of(:user) }
    it { should validate_presence_of(:source) }
    it { should ensure_inclusion_of(:access_level).in_array(Gitlab::Access.values) }
  end

  describe "Delegate methods" do
    it { should respond_to(:user_name) }
    it { should respond_to(:user_email) }
  end
end
