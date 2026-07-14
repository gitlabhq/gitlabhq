# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Authn::IamService::RejectConsentChallengeService, feature_category: :system_access do
  let_it_be(:user) { create(:user) }
  let_it_be(:oauth_application) { create(:oauth_application) }

  let(:iam_service_url) { 'https://iam.example.com' }
  let(:challenge) { 'a' * 64 }
  let(:client_id) { oauth_application.uid }
  let(:client_name) { 'Test App' }
  let(:requested_scopes) { %w[openid profile email] }
  let(:client_scopes) { %w[openid profile email] }
  let(:ip_address) { '198.51.100.42' }
  let(:user_agent) { 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)' }
  let(:redirect_url) { "#{iam_service_url}/oauth2/authorize?error=access_denied" }

  let(:grpc_client) { instance_double(Authn::IamService::GrpcClient) }
  let(:service_kwargs) do
    {
      challenge: challenge,
      user: user,
      client_id: client_id,
      client_name: client_name,
      requested_scopes: requested_scopes,
      client_scopes: client_scopes,
      ip_address: ip_address,
      user_agent: user_agent,
      client: grpc_client
    }
  end

  let(:service) { described_class.new(**service_kwargs) }

  subject(:result) { service.execute }

  before do
    allow(Authn::IamAuthService).to receive(:url).and_return(iam_service_url)
  end

  describe '#execute' do
    let(:response) { ::Gitlab::Iam::Auth::V1::ConsentServiceRejectResponse.new(redirect_to: redirect_url) }

    before do
      allow(grpc_client).to receive(:reject_consent_challenge).and_return(response)
    end

    context 'when the response is valid' do
      it 'returns the redirect URL', :aggregate_failures do
        expect(result).to be_success
        expect(result.payload[:redirect_to]).to eq(redirect_url)
      end

      it 'sends the correct gRPC request' do
        result

        expect(grpc_client).to have_received(:reject_consent_challenge).with(challenge: challenge)
      end

      it 'creates a rejected consent record', :aggregate_failures do
        expect { result }.to change { Authn::OauthConsent.count }.by(1)

        consent = Authn::OauthConsent.last
        expect(consent.consent_challenge).to eq(challenge)
        expect(consent.user).to eq(user)
        expect(consent.client_id).to eq(client_id)
        expect(consent.requested_scopes).to eq(requested_scopes)
        expect(consent.granted_scopes).to eq([])
        expect(consent).to be_rejected
      end

      it 'emits an audit event' do
        expect(::Gitlab::Audit::Auditor).to receive(:audit).with({
          name: 'user_rejected_iam_oauth_application',
          author: user,
          scope: user,
          target: user,
          target_details: client_name,
          message: 'User rejected an OAuth application.',
          additional_details: {
            application_id: client_id,
            application_name: client_name,
            scopes: client_scopes,
            requested_scopes: requested_scopes,
            granted_scopes: [],
            user_agent: user_agent
          },
          ip_address: ip_address
        })

        result
      end

      context 'when ip_address and user_agent are not provided' do
        let(:service_kwargs) { super().except(:ip_address, :user_agent) }

        it 'emits an audit event with nil ip_address and user_agent' do
          expect(::Gitlab::Audit::Auditor).to receive(:audit).with(
            hash_including(
              ip_address: nil,
              additional_details: hash_including(user_agent: nil)
            )
          )

          result
        end
      end
    end

    context 'when the consent record is invalid' do
      let(:log_message) { 'IAM consent challenge reject failed' }

      before do
        allow(Authn::OauthConsent).to receive(:create!).and_raise(ActiveRecord::RecordInvalid.new(Authn::OauthConsent.new))
      end

      include_examples 'iam consent persistence failure handling'
    end

    context 'when the consent record already exists' do
      let(:log_message) { 'IAM consent challenge reject failed' }

      before do
        create(:oauth_consent, consent_challenge: challenge, user: user, client_id: client_id)
      end

      include_examples 'iam consent persistence failure handling'
    end

    context 'when the gRPC client raises a RequestError' do
      before do
        allow(grpc_client).to receive(:reject_consent_challenge)
          .and_raise(Authn::IamService::GrpcClient::RequestError, 'Failed to connect to IAM service')
      end

      it_behaves_like 'does not create a consent record'

      include_examples 'iam service error response with user',
        reason: :service_unavailable,
        message: 'Failed to connect to IAM service'

      include_examples 'does not emit IAM consent audit event'
    end

    context 'when redirect_to is missing' do
      let(:response) { ::Gitlab::Iam::Auth::V1::ConsentServiceRejectResponse.new(redirect_to: '') }

      it_behaves_like 'does not create a consent record'

      include_examples 'iam service error response with user',
        reason: :invalid_response,
        message: 'IAM consent reject response missing redirect_to'

      include_examples 'does not emit IAM consent audit event'
    end

    context 'when redirect_to is an untrusted URL' do
      let(:response) { ::Gitlab::Iam::Auth::V1::ConsentServiceRejectResponse.new(redirect_to: 'https://untrusted.example.com/oauth2/authorize') }

      it_behaves_like 'does not create a consent record'

      include_examples 'iam service error response with user',
        reason: :invalid_redirect_url,
        message: 'IAM consent reject response contains invalid redirect URL'

      include_examples 'does not emit IAM consent audit event'
    end
  end
end
