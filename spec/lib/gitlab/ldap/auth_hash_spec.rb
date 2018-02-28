require 'spec_helper'

describe Gitlab::LDAP::AuthHash do
  let(:auth_hash) do
    described_class.new(
      OmniAuth::AuthHash.new(
        uid: given_uid,
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
    let(:given_uid) { 'uid=John Smith,ou=People,dc=example,dc=com' }

    it "has the correct username" do
      expect(auth_hash.username).to eq("123456")
    end

    it "has the correct name" do
      expect(auth_hash.name).to eq("Smith, J.")
    end
  end

  context "with overridden attributes" do
    let(:given_uid) { 'uid=John Smith,ou=People,dc=example,dc=com' }

    let(:attributes) do
      {
        'username'  => %w(mail email),
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

  describe '#uid' do
    context 'when there is extraneous (but valid) whitespace' do
      let(:given_uid) { 'uid     =john smith ,  ou = people, dc=  example,dc =com' }

      it 'removes the extraneous whitespace' do
        expect(auth_hash.uid).to eq('uid=john smith,ou=people,dc=example,dc=com')
      end
    end

    context 'when there are upper case characters' do
      let(:given_uid) { 'UID=John Smith,ou=People,dc=example,dc=com' }

      it 'downcases' do
        expect(auth_hash.uid).to eq('uid=john smith,ou=people,dc=example,dc=com')
      end
    end
  end
end
