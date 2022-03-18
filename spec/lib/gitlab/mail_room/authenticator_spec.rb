# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::MailRoom::Authenticator do
  let(:yml_config) do
    {
      enabled: true,
      address: 'address@example.com'
    }
  end

  let(:incoming_email_secret_path) { '/path/to/incoming_email_secret' }
  let(:incoming_email_config) { yml_config.merge(secret_file: incoming_email_secret_path) }

  let(:service_desk_email_secret_path) { '/path/to/service_desk_email_secret' }
  let(:service_desk_email_config) { yml_config.merge(secret_file: service_desk_email_secret_path) }

  let(:configs) do
    {
      incoming_email: incoming_email_config,
      service_desk_email: service_desk_email_config
    }
  end

  before do
    allow(Gitlab::MailRoom).to receive(:enabled_configs).and_return(configs)

    described_class.clear_memoization(:jwt_secret_incoming_email)
    described_class.clear_memoization(:jwt_secret_service_desk_email)
  end

  after do
    described_class.clear_memoization(:jwt_secret_incoming_email)
    described_class.clear_memoization(:jwt_secret_service_desk_email)
  end

  around do |example|
    freeze_time do
      example.run
    end
  end

  describe '#verify_api_request' do
    let(:incoming_email_secret) { SecureRandom.hex(16) }
    let(:service_desk_email_secret) { SecureRandom.hex(16) }
    let(:payload) { { iss: Gitlab::MailRoom::INTERNAL_API_REQUEST_JWT_ISSUER, iat: (Time.current - 5.minutes + 1.second).to_i } }

    before do
      allow(described_class).to receive(:secret).with(:incoming_email).and_return(incoming_email_secret)
      allow(described_class).to receive(:secret).with(:service_desk_email).and_return(service_desk_email_secret)
    end

    context 'verify a valid token' do
      it 'returns the decoded payload' do
        encoded_token = JWT.encode(payload, incoming_email_secret, 'HS256')
        headers = { Gitlab::MailRoom::INTERNAL_API_REQUEST_HEADER => encoded_token }

        expect(described_class.verify_api_request(headers, 'incoming_email')[0]).to match a_hash_including(
          "iss" => "gitlab-mailroom",
          "iat" => be_a(Integer)
        )

        encoded_token = JWT.encode(payload, service_desk_email_secret, 'HS256')
        headers = { Gitlab::MailRoom::INTERNAL_API_REQUEST_HEADER => encoded_token }

        expect(described_class.verify_api_request(headers, 'service_desk_email')[0]).to match a_hash_including(
          "iss" => "gitlab-mailroom",
          "iat" => be_a(Integer)
        )
      end
    end

    context 'verify an invalid token' do
      it 'returns false' do
        encoded_token = JWT.encode(payload, 'wrong secret', 'HS256')
        headers = { Gitlab::MailRoom::INTERNAL_API_REQUEST_HEADER => encoded_token }

        expect(described_class.verify_api_request(headers, 'incoming_email')).to eq(false)
      end
    end

    context 'verify a valid token but wrong mailbox type' do
      it 'returns false' do
        encoded_token = JWT.encode(payload, incoming_email_secret, 'HS256')
        headers = { Gitlab::MailRoom::INTERNAL_API_REQUEST_HEADER => encoded_token }

        expect(described_class.verify_api_request(headers, 'service_desk_email')).to eq(false)
      end
    end

    context 'verify a valid token but wrong issuer' do
      let(:payload) { { iss: 'invalid_issuer' } }

      it 'returns false' do
        encoded_token = JWT.encode(payload, incoming_email_secret, 'HS256')
        headers = { Gitlab::MailRoom::INTERNAL_API_REQUEST_HEADER => encoded_token }

        expect(described_class.verify_api_request(headers, 'incoming_email')).to eq(false)
      end
    end

    context 'verify a valid token but expired' do
      let(:payload) { { iss: Gitlab::MailRoom::INTERNAL_API_REQUEST_JWT_ISSUER, iat: (Time.current - 5.minutes - 1.second).to_i } }

      it 'returns false' do
        encoded_token = JWT.encode(payload, incoming_email_secret, 'HS256')
        headers = { Gitlab::MailRoom::INTERNAL_API_REQUEST_HEADER => encoded_token }

        expect(described_class.verify_api_request(headers, 'incoming_email')).to eq(false)
      end
    end

    context 'verify a valid token but wrong header field' do
      it 'returns false' do
        encoded_token = JWT.encode(payload, incoming_email_secret, 'HS256')
        headers = { 'a-wrong-header' => encoded_token }

        expect(described_class.verify_api_request(headers, 'incoming_email')).to eq(false)
      end
    end

    context 'verify headers for a disabled mailbox type' do
      let(:configs) { { service_desk_email: service_desk_email_config } }

      it 'returns false' do
        encoded_token = JWT.encode(payload, incoming_email_secret, 'HS256')
        headers = { Gitlab::MailRoom::INTERNAL_API_REQUEST_HEADER => encoded_token }

        expect(described_class.verify_api_request(headers, 'incoming_email')).to eq(false)
      end
    end

    context 'verify headers for a non-existing mailbox type' do
      it 'returns false' do
        headers = { Gitlab::MailRoom::INTERNAL_API_REQUEST_HEADER => 'something' }

        expect(described_class.verify_api_request(headers, 'invalid_mailbox_type')).to eq(false)
      end
    end
  end

  describe '#secret' do
    let(:incoming_email_secret) { SecureRandom.hex(16) }
    let(:service_desk_email_secret) { SecureRandom.hex(16) }

    context 'the secret is valid' do
      before do
        allow(described_class).to receive(:read_secret).with(incoming_email_secret_path).and_return(incoming_email_secret).once
        allow(described_class).to receive(:read_secret).with(service_desk_email_secret_path).and_return(service_desk_email_secret).once
      end

      it 'returns the memorized secret from a file' do
        expect(described_class.secret(:incoming_email)).to eql(incoming_email_secret)
        # The second call does not trigger secret read again
        expect(described_class.secret(:incoming_email)).to eql(incoming_email_secret)
        expect(described_class).to have_received(:read_secret).with(incoming_email_secret_path).once

        expect(described_class.secret(:service_desk_email)).to eql(service_desk_email_secret)
        # The second call does not trigger secret read again
        expect(described_class.secret(:service_desk_email)).to eql(service_desk_email_secret)
        expect(described_class).to have_received(:read_secret).with(service_desk_email_secret_path).once
      end
    end

    context 'the secret file is not configured' do
      let(:incoming_email_config) { yml_config }

      it 'raises a SecretConfigurationError exception' do
        expect do
          described_class.secret(:incoming_email)
        end.to raise_error(described_class::SecretConfigurationError, "incoming_email's secret_file configuration is missing")
      end
    end

    context 'the secret file not found' do
      before do
        allow(described_class).to receive(:read_secret).with(incoming_email_secret_path).and_raise(Errno::ENOENT)
      end

      it 'raises a SecretConfigurationError exception' do
        expect do
          described_class.secret(:incoming_email)
        end.to raise_error(described_class::SecretConfigurationError, "Fail to read incoming_email's secret: No such file or directory")
      end
    end
  end
end
