require 'spec_helper'

describe Gitlab::OAuth::AuthHash, lib: true do
  let(:auth_hash) do
    Gitlab::OAuth::AuthHash.new(
      OmniAuth::AuthHash.new(
        provider: provider_ascii,
        uid: uid_ascii,
        info: info_hash
      )
    )
  end

  let(:uid_raw) do
    "CN=Onur K\xC3\xBC\xC3\xA7\xC3\xBCk,OU=Test,DC=example,DC=net"
  end
  let(:email_raw) { "onur.k\xC3\xBC\xC3\xA7\xC3\xBCk_ABC-123@example.net" }
  let(:nickname_raw) { "ok\xC3\xBC\xC3\xA7\xC3\xBCk" }
  let(:first_name_raw) { 'Onur' }
  let(:last_name_raw) { "K\xC3\xBC\xC3\xA7\xC3\xBCk" }
  let(:name_raw) { "Onur K\xC3\xBC\xC3\xA7\xC3\xBCk" }

  let(:provider_ascii) { 'ldap'.force_encoding(Encoding::ASCII_8BIT) }
  let(:uid_ascii) { uid_raw.force_encoding(Encoding::ASCII_8BIT) }
  let(:email_ascii) { email_raw.force_encoding(Encoding::ASCII_8BIT) }
  let(:nickname_ascii) { nickname_raw.force_encoding(Encoding::ASCII_8BIT) }
  let(:first_name_ascii) { first_name_raw.force_encoding(Encoding::ASCII_8BIT) }
  let(:last_name_ascii) { last_name_raw.force_encoding(Encoding::ASCII_8BIT) }
  let(:name_ascii) { name_raw.force_encoding(Encoding::ASCII_8BIT) }

  let(:provider_utf8) { provider_ascii.force_encoding(Encoding::UTF_8) }
  let(:uid_utf8) { uid_ascii.force_encoding(Encoding::UTF_8) }
  let(:email_utf8) { email_ascii.force_encoding(Encoding::UTF_8) }
  let(:nickname_utf8) { nickname_ascii.force_encoding(Encoding::UTF_8) }
  let(:name_utf8) { name_ascii.force_encoding(Encoding::UTF_8) }

  let(:info_hash) do
    {
      email:      email_ascii,
      first_name: first_name_ascii,
      last_name:  last_name_ascii,
      name:       name_ascii,
      nickname:   nickname_ascii,
      uid:        uid_ascii
    }
  end

  context 'defaults' do
    it { expect(auth_hash.provider).to eql provider_utf8 }
    it { expect(auth_hash.uid).to eql uid_utf8 }
    it { expect(auth_hash.email).to eql email_utf8 }
    it { expect(auth_hash.username).to eql nickname_utf8 }
    it { expect(auth_hash.name).to eql name_utf8 }
    it { expect(auth_hash.password).not_to be_empty }
  end

  context 'with kerberos provider' do
    let(:provider_ascii) { 'kerberos'.force_encoding(Encoding::ASCII_8BIT) }

    context "and uid contains a kerberos realm" do
      let(:uid_ascii) { 'mylogin@BAR.COM'.force_encoding(Encoding::ASCII_8BIT) }

      it "preserves the canonical uid" do
        expect(auth_hash.uid).to eq('mylogin@BAR.COM')
      end
    end

    context "and uid does not contain a kerberos realm" do
      let(:uid_ascii) { 'mylogin'.force_encoding(Encoding::ASCII_8BIT) }
      before do
        allow(Gitlab::Kerberos::Authentication).to receive(:kerberos_default_realm).and_return("FOO.COM")
      end

      it "canonicalizes uid with kerberos realm" do
        expect(auth_hash.uid).to eq('mylogin@FOO.COM')
      end
    end
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
      expect(auth_hash.username).to eql 'onur.kucuk_ABC-123'
    end
  end

  context 'name not provided' do
    before { info_hash.delete(:name) }

    it 'concats first and lastname as the name' do
      expect(auth_hash.name).to eql name_utf8
    end
  end

  context 'auth_hash constructed with ASCII-8BIT encoding' do
    it 'forces utf8 encoding on uid' do
      expect(auth_hash.uid.encoding).to eql Encoding::UTF_8
    end

    it 'forces utf8 encoding on provider' do
      expect(auth_hash.provider.encoding).to eql Encoding::UTF_8
    end

    it 'forces utf8 encoding on name' do
      expect(auth_hash.name.encoding).to eql Encoding::UTF_8
    end

    it 'forces utf8 encoding on username' do
      expect(auth_hash.username.encoding).to eql Encoding::UTF_8
    end

    it 'forces utf8 encoding on email' do
      expect(auth_hash.email.encoding).to eql Encoding::UTF_8
    end

    it 'forces utf8 encoding on password' do
      expect(auth_hash.password.encoding).to eql Encoding::UTF_8
    end
  end
end
