# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AuditEvents::GoogleCloud::Authentication, feature_category: :audit_events do
  describe '#generate_access_token' do
    let_it_be(:client_email) { 'test@example.com' }
    let_it_be(:private_key) { 'private_key' }
    let_it_be(:scope) { 'https://www.googleapis.com/auth/logging.write' }
    let_it_be(:json_key_io) { StringIO.new({ client_email: client_email, private_key: private_key }.to_json) }

    subject(:generate_access_token) do
      described_class.new(scope: scope).generate_access_token(client_email, private_key)
    end

    context 'with doubled service_account_credentials' do
      let(:service_account_credentials) { instance_double('Google::Auth::ServiceAccountCredentials') }

      before do
        allow(Google::Auth::ServiceAccountCredentials)
          .to receive(:make_creds).with(json_key_io: json_key_io, scope: scope).and_return(service_account_credentials)
        allow(StringIO).to receive(:new)
          .with({ client_email: client_email, private_key: private_key }.to_json)
          .and_return(json_key_io)
      end

      context 'when credentials are valid' do
        before do
          allow(service_account_credentials).to receive(:fetch_access_token!).and_return({ 'access_token' => 'token' })
        end

        it 'calls make_creds with correct parameters' do
          expect(Google::Auth::ServiceAccountCredentials)
            .to receive(:make_creds).with(json_key_io: json_key_io, scope: scope)

          generate_access_token
        end

        it 'returns the access token string' do
          expect(generate_access_token).to eq('token')
        end
      end

      context 'when fetch_access_token! raises OpenSSL::PKey::RSAError' do
        let(:error) { OpenSSL::PKey::RSAError.new('invalid private key') }

        before do
          allow(service_account_credentials).to receive(:fetch_access_token!).and_raise(error)
        end

        it 'propagates the error to the caller' do
          expect(Gitlab::ErrorTracking).not_to receive(:log_exception)
          expect(Gitlab::ErrorTracking).not_to receive(:track_exception)

          expect { generate_access_token }.to raise_error(OpenSSL::PKey::RSAError, 'invalid private key')
        end
      end

      context 'when fetch_access_token! raises Signet::AuthorizationError' do
        let(:error) { Signet::AuthorizationError.new('unauthorized') }

        before do
          allow(service_account_credentials).to receive(:fetch_access_token!).and_raise(error)
        end

        it 'propagates the error to the caller' do
          expect(Gitlab::ErrorTracking).not_to receive(:log_exception)
          expect(Gitlab::ErrorTracking).not_to receive(:track_exception)

          expect { generate_access_token }.to raise_error(Signet::AuthorizationError, /unauthorized/)
        end
      end

      context 'when fetch_access_token! raises an unexpected StandardError' do
        let(:error) { StandardError.new('unexpected') }

        before do
          allow(service_account_credentials).to receive(:fetch_access_token!).and_raise(error)
        end

        it 'propagates the error to the caller without tracking it' do
          expect(Gitlab::ErrorTracking).not_to receive(:track_exception)
          expect(Gitlab::ErrorTracking).not_to receive(:log_exception)

          expect { generate_access_token }.to raise_error(StandardError, 'unexpected')
        end
      end
    end

    context 'with a real invalid private key' do
      let(:client_email) { 'test@example.com' }
      let(:private_key) { '' }

      it 'propagates the error raised by the underlying Google auth library' do
        expect { described_class.new(scope: scope).generate_access_token(client_email, private_key) }
          .to raise_error(OpenSSL::PKey::RSAError)
      end
    end

    context 'when make_creds raises' do
      let(:error) { OpenSSL::PKey::RSAError.new('Neither PUB key nor PRIV key') }

      before do
        allow(Google::Auth::ServiceAccountCredentials)
          .to receive(:make_creds).and_raise(error)
      end

      it 'propagates the error to the caller' do
        expect { generate_access_token }.to raise_error(OpenSSL::PKey::RSAError, /Neither PUB key nor PRIV key/)
      end
    end
  end
end
