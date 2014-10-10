require 'spec_helper'

describe Gitlab::OAuth::AuthHash do
  let(:auth_hash) do
    Gitlab::OAuth::AuthHash.new(double({
      provider: 'twitter',
      uid: uid,
      info: double(info_hash)
    }))
  end
  let(:uid) { 'my-uid' }
  let(:email) { 'my-email@example.com' }
  let(:nickname) { 'my-nickname' }
  let(:info_hash) {
    {
      email: email,
      nickname: nickname,
      name: 'John',
      first_name: "John",
      last_name: "Who"
    }
  }

  context "defaults" do
    it { expect(auth_hash.provider).to eql 'twitter' }
    it { expect(auth_hash.uid).to eql uid }
    it { expect(auth_hash.email).to eql email }
    it { expect(auth_hash.username).to eql nickname }
    it { expect(auth_hash.name).to eql "John" }
    it { expect(auth_hash.password).to_not be_empty }
  end

  context "email not provided" do
    before { info_hash.delete(:email) }
    it "generates a temp email" do
      expect( auth_hash.email).to start_with('temp-email-for-oauth')
    end
  end

  context "username not provided" do
    before { info_hash.delete(:nickname) }

    it "takes the first part of the email as username" do
      expect( auth_hash.username ).to eql "my-email"
    end
  end

  context "name not provided" do
    before { info_hash.delete(:name) }

    it "concats first and lastname as the name" do
      expect( auth_hash.name ).to eql "John Who"
    end
  end
end