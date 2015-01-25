require 'spec_helper'

describe Gitlab::OAuth::AuthHash do
  let(:auth_hash) do
    Gitlab::OAuth::AuthHash.new(double({
      provider: provider_ascii,
      uid: uid_ascii,
      info: double(info_hash)
    }))
  end

  let(:provider_ascii) { 'ldap'.force_encoding(Encoding::ASCII_8BIT) }
  let(:uid_ascii) { "CN=John B\xC4\x99ben,OU=Test,DC=company,DC=org".force_encoding(Encoding::ASCII_8BIT) }
  let(:email_ascii) { "john.b\xC4\x99ben@company.org".force_encoding(Encoding::ASCII_8BIT) }
  let(:nickname_ascii) { "jb\xC4\x99ben".force_encoding(Encoding::ASCII_8BIT) }
  let(:first_name_ascii) { 'John'.force_encoding(Encoding::ASCII_8BIT) }
  let(:last_name_ascii) { "B\xC4\x99ben".force_encoding(Encoding::ASCII_8BIT) }
  let(:name_ascii) { "John B\xC4\x99ben".force_encoding(Encoding::ASCII_8BIT) }

  let(:provider_utf8) { provider_ascii.force_encoding(Encoding::UTF_8) }
  let(:uid_utf8) { uid_ascii.force_encoding(Encoding::UTF_8) }
  let(:email_utf8) { email_ascii.force_encoding(Encoding::UTF_8) }
  let(:nickname_utf8) { nickname_ascii.force_encoding(Encoding::UTF_8) }
  let(:name_utf8) { name_ascii.force_encoding(Encoding::UTF_8) }

  let(:info_hash) {
    {
      email: email_ascii,
      first_name: first_name_ascii,
      last_name: last_name_ascii,
      name: name_ascii,
      nickname: nickname_ascii,
      uid: uid_ascii
    }
  }

  context 'defaults' do
    it { expect(auth_hash.provider).to eql provider_utf8 }
    it { expect(auth_hash.uid).to eql uid_utf8 }
    it { expect(auth_hash.email).to eql email_utf8 }
    it { expect(auth_hash.username).to eql nickname_utf8 }
    it { expect(auth_hash.name).to eql name_utf8 }
    it { expect(auth_hash.password).to_not be_empty }
  end

  context 'email not provided' do
    before { info_hash.delete(:email) }

    it 'generates a temp email' do
      expect( auth_hash.email).to start_with('temp-email-for-oauth')
    end
  end

  context 'username not provided' do
    before { info_hash.delete(:nickname) }

    it 'takes the first part of the email as username' do
      expect( auth_hash.username ).to eql 'john-beben'
    end
  end

  context 'name not provided' do
    before { info_hash.delete(:name) }

    it 'concats first and lastname as the name' do
      expect( auth_hash.name ).to eql name_utf8
    end
  end

  context 'auth_hash constructed with ASCII-8BIT encoding' do
    it 'forces utf8 encoding on uid' do
      auth_hash.uid.encoding.should == Encoding::UTF_8
    end

    it 'forces utf8 encoding on provider' do
      auth_hash.provider.encoding.should == Encoding::UTF_8
    end

    it 'forces utf8 encoding on name' do
      auth_hash.name.encoding.should == Encoding::UTF_8
    end

    it 'forces utf8 encoding on full_name' do
      auth_hash.full_name.encoding.should == Encoding::UTF_8
    end

    it 'forces utf8 encoding on username' do
      auth_hash.username.encoding.should == Encoding::UTF_8
    end

    it 'forces utf8 encoding on email' do
      auth_hash.email.encoding.should == Encoding::UTF_8
    end

    it 'forces utf8 encoding on password' do
      auth_hash.password.encoding.should == Encoding::UTF_8
    end
  end
end
