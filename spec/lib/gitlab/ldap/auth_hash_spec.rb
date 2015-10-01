require 'spec_helper'

describe Gitlab::LDAP::AuthHash do
  let(:auth_hash) do
    Gitlab::LDAP::AuthHash.new(
      OmniAuth::AuthHash.new(
        uid: '123456', 
        provider: 'ldapmain', 
        info: info,
        extra: {
          raw_info: raw_info
        }
      )
    )
  end

  let(:info) do
    {
      name:     'Smith, J.',
      email:    'johnsmith@example.com',
      nickname: '123456'
    }
  end

  let(:raw_info) do
    {
      uid:      ['123456'],
      email:    ['johnsmith@example.com'],
      cn:       ['Smith, J.'],
      fullName: ['John Smith']
    }
  end

  context "without overridden attributes" do

    it "has the correct username" do
      expect(auth_hash.username).to eq("123456") 
    end

    it "has the correct name" do
      expect(auth_hash.name).to eq("Smith, J.") 
    end
  end

  context "with overridden attributes" do
    let(:attributes) do
      {
        'username'  => ['mail', 'email'],
        'name'      => 'fullName'
      }
    end

    before do
      allow_any_instance_of(Gitlab::LDAP::Config).to receive(:attributes).and_return(attributes)
    end

    it "has the correct username" do
      expect(auth_hash.username).to eq("johnsmith@example.com") 
    end

    it "has the correct name" do
      expect(auth_hash.name).to eq("John Smith") 
    end
  end
end
