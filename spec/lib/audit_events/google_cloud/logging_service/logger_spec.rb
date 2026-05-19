# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AuditEvents::GoogleCloud::LoggingService::Logger, feature_category: :audit_events do
  let_it_be(:client_email) { 'test@example.com' }
  let_it_be(:private_key) { 'private_key' }
  let_it_be(:payload) { [{ logName: 'test-log' }.to_json] }
  let_it_be(:access_token) { 'access_token' }
  let_it_be(:expected_headers) do
    { 'Authorization' => "Bearer #{access_token}", 'Content-Type' => 'application/json' }
  end

  subject(:log) { described_class.new.log(client_email, private_key, payload) }

  describe '#log' do
    context 'when access token is available' do
      before do
        allow_next_instance_of(AuditEvents::GoogleCloud::Authentication) do |instance|
          allow(instance).to receive(:generate_access_token).with(client_email, private_key).and_return(access_token)
        end
      end

      it 'generates access token and calls Gitlab::HTTP.post with correct parameters' do
        expect(Gitlab::HTTP).to receive(:post).with(
          described_class::WRITE_URL,
          body: payload,
          headers: expected_headers
        )

        log
      end

      context 'when URI::InvalidURIError is raised' do
        before do
          allow(Gitlab::HTTP).to receive(:post).and_raise(URI::InvalidURIError.new('bad uri'))
        end

        it 'propagates the error to the caller' do
          expect { log }.to raise_error(URI::InvalidURIError, /bad uri/)
        end
      end

      context 'when a Gitlab::HTTP::HTTP_ERRORS member is raised' do
        Gitlab::HTTP::HTTP_ERRORS.each do |error_klass|
          context "with #{error_klass}" do
            before do
              allow(Gitlab::HTTP).to receive(:post).and_raise(error_klass.new('http error'))
            end

            it 'propagates the error to the caller' do
              expect { log }.to raise_error(error_klass)
            end
          end
        end
      end
    end

    context 'when generate_access_token raises an error' do
      let(:error) { OpenSSL::PKey::RSAError.new('invalid private key') }

      before do
        allow_next_instance_of(AuditEvents::GoogleCloud::Authentication) do |instance|
          allow(instance).to receive(:generate_access_token).with(client_email, private_key).and_raise(error)
        end
      end

      it 'propagates the error and does not call Gitlab::HTTP.post' do
        expect(Gitlab::HTTP).not_to receive(:post)

        expect { log }.to raise_error(OpenSSL::PKey::RSAError, 'invalid private key')
      end
    end
  end
end
