# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Auth::OAuth::AuthHash, :aggregate_failures, feature_category: :user_management do
  let(:provider) { 'openid_connect' }
  let(:auth_hash) do
    described_class.new(
      OmniAuth::AuthHash.new(
        provider: provider,
        uid: uid_ascii,
        info: info_hash,
        extra: {
          raw_info: {
            'https://example.com/claims/username': username_claim_utf8
          }
        }
      )
    )
  end

  let(:uid_raw) do
    +"CN=Onur K\xC3\xBC\xC3\xA7\xC3\xBCk,OU=Test,DC=example,DC=net"
  end

  let(:email_raw) { +"onur.k\xC3\xBC\xC3\xA7\xC3\xBCk_ABC-123@example.net" }
  let(:nickname_raw) { +"ok\xC3\xBC\xC3\xA7\xC3\xBCk" }
  let(:first_name_raw) { +'Onur' }
  let(:last_name_raw) { +"K\xC3\xBC\xC3\xA7\xC3\xBCk" }
  let(:name_raw) { +"Onur K\xC3\xBC\xC3\xA7\xC3\xBCk" }
  let(:username_claim_raw) { +'onur.partner' }

  let(:uid_ascii) { uid_raw.force_encoding(Encoding::ASCII_8BIT) }
  let(:email_ascii) { email_raw.force_encoding(Encoding::ASCII_8BIT) }
  let(:nickname_ascii) { nickname_raw.force_encoding(Encoding::ASCII_8BIT) }
  let(:first_name_ascii) { first_name_raw.force_encoding(Encoding::ASCII_8BIT) }
  let(:last_name_ascii) { last_name_raw.force_encoding(Encoding::ASCII_8BIT) }
  let(:name_ascii) { name_raw.force_encoding(Encoding::ASCII_8BIT) }

  let(:uid_utf8) { uid_ascii.force_encoding(Encoding::UTF_8) }
  let(:email_utf8) { email_ascii.force_encoding(Encoding::UTF_8) }
  let(:nickname_utf8) { nickname_ascii.force_encoding(Encoding::UTF_8) }
  let(:name_utf8) { name_ascii.force_encoding(Encoding::UTF_8) }
  let(:first_name_utf8) { first_name_ascii.force_encoding(Encoding::UTF_8) }
  let(:username_claim_utf8) { username_claim_raw.force_encoding(Encoding::ASCII_8BIT) }

  let(:info_hash) do
    {
      email: email_ascii,
      first_name: first_name_ascii,
      last_name: last_name_ascii,
      name: name_ascii,
      nickname: nickname_ascii,
      uid: uid_ascii,
      address: {
        locality: 'some locality',
        country: 'some country'
      }
    }
  end

  context 'defaults' do
    it { expect(auth_hash.provider).to eq provider }
    it { expect(auth_hash.uid).to eql uid_utf8 }
    it { expect(auth_hash.email).to eql email_utf8 }
    it { expect(auth_hash.username).to eql nickname_utf8 }
    it { expect(auth_hash.name).to eql name_utf8 }
    it { expect(auth_hash.password).not_to be_empty }
    it { expect(auth_hash.location).to eq 'some locality, some country' }
    it { expect(auth_hash.errors).to be_empty }
  end

  context 'email not provided' do
    before do
      info_hash.delete(:email)
    end

    it 'generates a temp email' do
      expect(auth_hash.email).to start_with('temp-email-for-oauth')
    end
  end

  context 'username not provided' do
    before do
      info_hash.delete(:nickname)
    end

    it 'takes the first part of the email as username' do
      expect(auth_hash.username).to eql 'onur.kucuk_ABC-123'
    end
  end

  context 'when username claim is in email format' do
    let(:info_hash) do
      {
        email: nil,
        name: 'GitLab test',
        nickname: 'GitLab@gitlabsandbox.onmicrosoft.com',
        uid: uid_ascii
      }
    end

    it 'creates proper email and username fields' do
      expect(auth_hash.username).to eql 'GitLab'
      expect(auth_hash.email).to eql 'temp-email-for-oauth-GitLab@gitlab.localhost'
    end
  end

  context 'name not provided' do
    before do
      info_hash.delete(:name)
    end

    it 'concats first and lastname as the name' do
      expect(auth_hash.name).to eql name_utf8
    end
  end

  context 'custom username field provided' do
    let(:provider_config) do
      GitlabSettings::Options.build(
        {
          name: provider,
          args: { 'gitlab_username_claim' => 'first_name' }
        }
      )
    end

    before do
      stub_omniauth_setting(providers: [provider_config])
    end

    it 'uses the custom field for the username within info' do
      expect(auth_hash.username).to eql first_name_utf8
    end

    it 'uses the custom field for the username within extra.raw_info' do
      provider_config['args']['gitlab_username_claim'] = 'https://example.com/claims/username'

      expect(auth_hash.username).to eql username_claim_utf8
    end

    it 'uses the default claim for the username when the custom claim is not found' do
      provider_config['args']['gitlab_username_claim'] = 'nonexistent'

      expect(auth_hash.username).to eql nickname_utf8
    end

    it 'uses the default claim for the username when the custom claim is empty' do
      info_hash[:first_name] = ''

      expect(auth_hash.username).to eql nickname_utf8
    end

    it 'uses the default claim for the username when the custom claim is nil' do
      info_hash[:first_name] = nil

      expect(auth_hash.username).to eql nickname_utf8
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

  context 'for email address length validation prior to generating a username' do
    let(:info_hash) do
      {
        email: email,
        name: 'GitLab test',
        uid: uid_ascii
      }
    end

    context 'when the email address is not too long' do
      let(:local_part) { generate(:username) }
      let(:email) { "#{local_part}@example.com" }

      it 'normalizes the string' do
        expect(auth_hash).to receive(:mb_chars_unicode_normalize).and_call_original

        expect(auth_hash.username).to eq(local_part)
        expect(auth_hash.errors).to eq({})
      end
    end

    context 'when the whole email address is longer than 254 characters' do
      # Email with unicode characters
      def long_email_local_part
        "longemail𒐫" * 300
      end

      let(:email) { "#{long_email_local_part}@example.com" }

      it 'produces an error and does not normalize the string' do
        expect(auth_hash).not_to receive(:mb_chars_unicode_normalize).and_call_original

        expect(auth_hash.username).to be_empty
        expect(auth_hash.errors).to eq({ identity_provider_email: _("must be 254 characters or less.") })
      end
    end

    context 'when the local part of the email address is longer than 254 characters after normalization' do
      # Email with unicode characters that normalize to multiple characters
      def long_email_local_part
        "email℀℀℀℀℀" * 24
      end

      let(:email) { "#{long_email_local_part}@example.com" }

      it 'normalizes the string and produces an error' do
        expect(auth_hash).to receive(:mb_chars_unicode_normalize).and_call_original

        expect(auth_hash.username).to be_empty
        expect(auth_hash.errors).to eq({ identity_provider_email: _("must be 254 characters or less.") })
      end
    end
  end

  describe '#get_from_auth_hash_or_info' do
    context 'for a key not within auth_hash' do
      let(:auth_hash) do
        described_class.new(
          OmniAuth::AuthHash.new(
            provider: provider,
            uid: uid_ascii,
            info: info_hash
          )
        )
      end

      let(:info_hash) { { nickname: nickname_ascii } }

      it 'provides username from info_hash' do
        expect(auth_hash.username).to eql nickname_utf8
      end
    end

    context 'for a key within auth_hash' do
      let(:auth_hash) do
        described_class.new(
          OmniAuth::AuthHash.new(
            provider: provider,
            uid: uid_ascii,
            info: info_hash,
            username: nickname_ascii
          )
        )
      end

      let(:info_hash) { { something: nickname_ascii } }

      it 'provides username from auth_hash' do
        expect(auth_hash.username).to eql nickname_utf8
      end
    end

    context 'for a key within auth_hash extra' do
      let(:auth_hash) do
        described_class.new(
          OmniAuth::AuthHash.new(
            provider: provider,
            uid: uid_ascii,
            info: info_hash,
            extra: {
              raw_info: {
                nickname: nickname_ascii
              }
            }
          )
        )
      end

      let(:info_hash) { { something: nickname_ascii } }

      it 'provides username from auth_hash extra' do
        expect(auth_hash.username).to eql nickname_utf8
      end
    end
  end
end
