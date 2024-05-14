# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AuditEvents::GoogleCloud::Authentication, feature_category: :audit_events do
  describe '#generate_access_token' do
    let_it_be(:client_email) { 'test@example.com' }
    let_it_be(:private_key) { 'private_key' }
    let_it_be(:scope) { 'https://www.googleapis.com/auth/logging.write' }
    let_it_be(:json_key_io) { StringIO.new({ client_email: client_email, private_key: private_key }.to_json) }

    let(:service_account_credentials) { instance_double('Google::Auth::ServiceAccountCredentials') }

    subject(:generate_access_token) do
      described_class.new(scope: scope).generate_access_token(client_email, private_key)
    end

    before do
      allow(Google::Auth::ServiceAccountCredentials).to receive(:make_creds).with(json_key_io: json_key_io,
        scope: scope).and_return(service_account_credentials)
      allow(StringIO).to receive(:new).with({ client_email: client_email,
                                              private_key: private_key }.to_json).and_return(json_key_io)
    end

    context 'when credentials are valid' do
      before do
        allow(service_account_credentials).to receive(:fetch_access_token!).and_return({ 'access_token' => 'token' })
      end

      it 'calls make_creds with correct parameters' do
        expect(Google::Auth::ServiceAccountCredentials).to receive(:make_creds).with(json_key_io: json_key_io,
          scope: scope)

        generate_access_token
      end

      it 'fetches access token' do
        expect(generate_access_token).to eq('token')
      end
    end

    context 'when an error occurs' do
      before do
        allow(service_account_credentials).to receive(:fetch_access_token!).and_raise(StandardError)
      end

      it 'handles the exception and returns nil' do
        expect(Gitlab::ErrorTracking).to receive(:track_exception)
        expect(generate_access_token).to be_nil
      end
    end
  end
end
