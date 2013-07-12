require 'spec_helper'

describe SparkleInvite do
  describe "Associations" do
    it { should belong_to(:users_project) }
  end

  describe "Validation" do
    let!(:sparkle_invite) { create(:sparkle_invite) }

    it { should validate_presence_of(:users_project) }
  end

  it "should generate a token" do
    SecureRandom.stub(:hex).and_return('123456789')
    sparkle_invite = create :sparkle_invite
    sparkle_invite.token.should == '123456789'
  end

  it "should be acceptable?" do
    sparkle_invite = create(:sparkle_invite)
    sparkle_invite.should be_acceptable
  end

  describe "#accept!" do
    let(:sparkle_invite) { create(:sparkle_invite) }
    let(:public_key) { "ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAIEAiPWx6WM4lhHNedGfBpPJNPpZ7yKu+dnn1SJejgt4596k6YjzGGphH2TUxwKzxcKDKKezwkpfnxPkSMkuEspGRt/aZZ9wa++Oi7Qkr8prgHc4soW6NUlfDzpvZK2H5E7eQaSeP3SAwGmQKUFHCddNaP0L+hM7zhFNzjFvpaMgJw0= host" }

    before do
      sparkle_invite.accept!(public_key)
    end

    it "should no longer be acceptable" do
      sparkle_invite.should_not be_acceptable
    end

    it "should have set the public key" do
      key = sparkle_invite.user.keys.last
      key.key.should == public_key
    end
  end
end
