# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::MailRoom::Authenticator, feature_category: :service_desk do
  let(:yml_config) do
    {
      enabled: true,
      address: 'address@example.com'
    }
  end

  let(:incoming_email_secret_path) { '/path/to/incoming_email_secret' }
  let(:incoming_email_public_key_path) { '/path/to/incoming_email_public_key' }
  let(:incoming_email_public_key_paths) { [incoming_email_public_key_path] }

  let(:service_desk_email_secret_path) { '/path/to/service_desk_email_secret' }
  let(:service_desk_email_public_key_path) { '/path/to/service_desk_email_public_key' }

  # A mailbox that only accepts the shared secret (HS256).
  let(:symmetric_config) { yml_config.merge(secret_file: incoming_email_secret_path) }

  # A mailbox that only accepts asymmetric tokens (ES256).
  let(:asymmetric_config) { yml_config.merge(public_key_files: incoming_email_public_key_paths) }

  # A mailbox in transition that accepts both.
  let(:dual_config) do
    yml_config.merge(secret_file: incoming_email_secret_path, public_key_files: incoming_email_public_key_paths)
  end

  let(:incoming_email_config) { symmetric_config }

  # A second mailbox with its own, distinct credentials, used to assert that a
  # token minted for one mailbox is never accepted by another.
  let(:service_desk_email_config) do
    yml_config.merge(
      secret_file: service_desk_email_secret_path,
      public_key_files: [service_desk_email_public_key_path]
    )
  end

  let(:configs) do
    {
      incoming_email: incoming_email_config,
      service_desk_email: service_desk_email_config
    }
  end

  let(:incoming_email_secret) { SecureRandom.hex(16) }
  let(:service_desk_email_secret) { SecureRandom.hex(16) }

  let(:private_key) { OpenSSL::PKey::EC.generate('prime256v1') }
  let(:public_key) { OpenSSL::PKey::EC.new(private_key.public_to_pem) }

  let(:service_desk_private_key) { OpenSSL::PKey::EC.generate('prime256v1') }
  let(:service_desk_public_key) { OpenSSL::PKey::EC.new(service_desk_private_key.public_to_pem) }

  let(:payload) do
    { iss: Gitlab::MailRoom::INTERNAL_API_REQUEST_JWT_ISSUER, iat: (Time.current - 5.minutes + 1.second).to_i }
  end

  before do
    allow(Gitlab::MailRoom).to receive(:enabled_configs).and_return(configs)

    allow(described_class).to receive(:read_secret).with(incoming_email_secret_path).and_return(incoming_email_secret)
    allow(described_class).to receive(:read_public_key).with(incoming_email_public_key_path).and_return(public_key)

    allow(described_class).to receive(:read_secret)
      .with(service_desk_email_secret_path).and_return(service_desk_email_secret)
    allow(described_class).to receive(:read_public_key)
      .with(service_desk_email_public_key_path).and_return(service_desk_public_key)

    clear_memoization
  end

  after do
    clear_memoization
  end

  def clear_memoization
    described_class.clear_memoization(:jwt_secret)
    described_class.clear_memoization(:jwt_public_key_set)
  end

  # The signer identifies the public key it signed with via the RFC 7638
  # thumbprint (`kid`), matching how the verifier builds its key set.
  def kid_for(key)
    JWT::JWK.new(key).export[:kid]
  end

  def headers_for(token)
    { Gitlab::MailRoom::INTERNAL_API_REQUEST_HEADER => token }
  end

  def symmetric_token(secret: incoming_email_secret, data: payload)
    JWT.encode(data, secret, 'HS256')
  end

  def asymmetric_token(key: private_key, kid: kid_for(public_key), data: payload)
    headers = kid ? { kid: kid } : {}
    JWT.encode(data, key, 'ES256', headers)
  end

  around do |example|
    freeze_time do
      example.run
    end
  end

  describe '#verify_api_request' do
    context 'for a symmetric-only mailbox' do
      let(:incoming_email_config) { symmetric_config }

      it 'verifies a valid HS256 token' do
        expect(described_class.verify_api_request(headers_for(symmetric_token), 'incoming_email')[0])
          .to match a_hash_including('iss' => 'gitlab-mailroom', 'iat' => be_a(Integer))
      end

      it 'returns false for a token signed with the wrong secret' do
        token = symmetric_token(secret: 'wrong secret')

        expect(described_class.verify_api_request(headers_for(token), 'incoming_email')).to eq(false)
      end

      it 'returns false for a valid token with the wrong issuer' do
        token = symmetric_token(data: { iss: 'invalid_issuer' })

        expect(described_class.verify_api_request(headers_for(token), 'incoming_email')).to eq(false)
      end

      it 'returns false for an expired token' do
        token = symmetric_token(data: payload.merge(iat: (Time.current - 5.minutes - 1.second).to_i))

        expect(described_class.verify_api_request(headers_for(token), 'incoming_email')).to eq(false)
      end

      it 'returns false when the token is in the wrong header field' do
        headers = { 'a-wrong-header' => symmetric_token }

        expect(described_class.verify_api_request(headers, 'incoming_email')).to eq(false)
      end

      it 'does not attempt asymmetric verification even if the token carries a kid' do
        expect(described_class.verify_api_request(headers_for(asymmetric_token), 'incoming_email')).to eq(false)
      end
    end

    context 'for an asymmetric-only mailbox' do
      let(:incoming_email_config) { asymmetric_config }

      it 'verifies a token signed with the matching private key and kid' do
        expect(described_class.verify_api_request(headers_for(asymmetric_token), 'incoming_email')[0])
          .to match a_hash_including('iss' => 'gitlab-mailroom', 'iat' => be_a(Integer))
      end

      it 'returns false for a token signed with a different private key' do
        token = asymmetric_token(key: OpenSSL::PKey::EC.generate('prime256v1'))

        expect(described_class.verify_api_request(headers_for(token), 'incoming_email')).to eq(false)
      end

      it 'returns false for a token with an unknown kid' do
        token = asymmetric_token(kid: 'unknown-kid')

        expect(described_class.verify_api_request(headers_for(token), 'incoming_email')).to eq(false)
      end

      it 'does not attempt symmetric verification for a token without a kid' do
        token = asymmetric_token(kid: nil)

        expect(described_class.verify_api_request(headers_for(token), 'incoming_email')).to eq(false)
      end

      it 'returns false for an HS256 token (rejects token-chosen algorithm)' do
        expect(described_class.verify_api_request(headers_for(symmetric_token), 'incoming_email')).to eq(false)
      end
    end

    context 'for a mailbox configured with both credentials (in transition)' do
      let(:incoming_email_config) { dual_config }

      it 'verifies a symmetric token when no kid is present' do
        expect(described_class.verify_api_request(headers_for(symmetric_token), 'incoming_email')[0])
          .to match a_hash_including('iss' => 'gitlab-mailroom')
      end

      it 'verifies an asymmetric token when a kid is present' do
        expect(described_class.verify_api_request(headers_for(asymmetric_token), 'incoming_email')[0])
          .to match a_hash_including('iss' => 'gitlab-mailroom')
      end

      it 'returns false for an HS256 token that carries a kid (routed to asymmetric)' do
        token = JWT.encode(payload, incoming_email_secret, 'HS256', { kid: kid_for(public_key) })

        expect(described_class.verify_api_request(headers_for(token), 'incoming_email')).to eq(false)
      end
    end

    context 'with multiple public keys configured (key rotation)' do
      let(:old_private_key) { OpenSSL::PKey::EC.generate('prime256v1') }
      let(:old_public_key) { OpenSSL::PKey::EC.new(old_private_key.public_to_pem) }
      let(:old_public_key_path) { '/path/to/incoming_email_old_public_key' }
      let(:incoming_email_public_key_paths) { [incoming_email_public_key_path, old_public_key_path] }
      let(:incoming_email_config) { asymmetric_config }

      before do
        allow(described_class).to receive(:read_public_key).with(old_public_key_path).and_return(old_public_key)
      end

      it 'verifies a token signed with the current key' do
        expect(described_class.verify_api_request(headers_for(asymmetric_token), 'incoming_email')[0])
          .to match a_hash_including('iss' => 'gitlab-mailroom')
      end

      it 'still verifies a token signed with the older key during rotation' do
        token = asymmetric_token(key: old_private_key, kid: kid_for(old_public_key))

        expect(described_class.verify_api_request(headers_for(token), 'incoming_email')[0])
          .to match a_hash_including('iss' => 'gitlab-mailroom')
      end
    end

    context 'cross-mailbox token isolation' do
      let(:incoming_email_config) { dual_config }

      it 'rejects an incoming_email symmetric token on the service_desk_email mailbox' do
        token = symmetric_token(secret: incoming_email_secret)

        expect(described_class.verify_api_request(headers_for(token), 'service_desk_email')).to eq(false)
      end

      it 'rejects a service_desk_email symmetric token on the incoming_email mailbox' do
        token = symmetric_token(secret: service_desk_email_secret)

        expect(described_class.verify_api_request(headers_for(token), 'incoming_email')).to eq(false)
      end

      it 'rejects an incoming_email asymmetric token on the service_desk_email mailbox' do
        token = asymmetric_token(key: private_key, kid: kid_for(public_key))

        expect(described_class.verify_api_request(headers_for(token), 'service_desk_email')).to eq(false)
      end

      it 'rejects a service_desk_email asymmetric token on the incoming_email mailbox' do
        token = asymmetric_token(key: service_desk_private_key, kid: kid_for(service_desk_public_key))

        expect(described_class.verify_api_request(headers_for(token), 'incoming_email')).to eq(false)
      end
    end

    context 'when the mailbox type is disabled' do
      let(:configs) { {} }

      it 'returns false' do
        expect(described_class.verify_api_request(headers_for(symmetric_token), 'incoming_email')).to eq(false)
      end
    end

    context 'when the mailbox type does not exist' do
      it 'returns false' do
        expect(described_class.verify_api_request(headers_for('something'), 'invalid_mailbox_type')).to eq(false)
      end
    end

    context 'logging' do
      it 'logs the failure without the error message or token value' do
        token = symmetric_token(secret: 'wrong secret')

        expect(Gitlab::AppLogger).to receive(:warn).with(
          Labkit::Fields::LOG_MESSAGE => 'Failed to decode MailRoom JWT token for incoming_email mailbox',
          Labkit::Fields::CLASS_NAME => described_class.name,
          Labkit::Fields::ERROR_TYPE => 'JWT::VerificationError'
        )

        described_class.verify_api_request(headers_for(token), 'incoming_email')
      end
    end

    context 'configuration errors' do
      context 'when the symmetric secret cannot be read' do
        let(:incoming_email_config) { symmetric_config }

        before do
          allow(described_class).to receive(:read_secret).with(incoming_email_secret_path).and_raise(Errno::ENOENT)
        end

        it 'raises a SecretConfigurationError' do
          expect do
            described_class.verify_api_request(headers_for(symmetric_token), 'incoming_email')
          end.to raise_error(described_class::SecretConfigurationError,
            "Failed to read incoming_email's secret: No such file or directory")
        end
      end

      context 'when an asymmetric public key cannot be read' do
        let(:incoming_email_config) { asymmetric_config }

        before do
          allow(described_class).to receive(:read_public_key)
            .with(incoming_email_public_key_path).and_raise(Errno::ENOENT)
        end

        it 'raises a SecretConfigurationError' do
          expect do
            described_class.verify_api_request(headers_for(asymmetric_token), 'incoming_email')
          end.to raise_error(described_class::SecretConfigurationError,
            "Failed to read incoming_email's public keys: No such file or directory")
        end
      end
    end
  end
end
