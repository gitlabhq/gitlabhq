# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Authn::IamService::AcceptLoginChallengeService, feature_category: :system_access do
  let_it_be(:user) { create(:user) }

  let(:iam_service_url) { 'https://iam.example.com' }
  let(:challenge) { 'a' * 64 }
  let(:redirect_url) { "#{iam_service_url}/oauth2/authorize?client_id=test-app&login_verifier=#{'b' * 64}" }

  let(:grpc_client) { instance_double(Authn::IamService::GrpcClient) }
  let(:service) { described_class.new(challenge: challenge, user: user, client: grpc_client) }

  subject(:result) { service.execute }

  before do
    allow(Authn::IamAuthService).to receive(:url).and_return(iam_service_url)
  end

  describe '#execute' do
    let(:response) { ::Auth::V1::LoginServiceAcceptResponse.new(redirect_to: redirect_url) }

    before do
      allow(grpc_client).to receive(:accept_login_challenge).and_return(response)
    end

    context 'when the IAM service accepts the challenge' do
      it 'returns a success response with the redirect URL', :aggregate_failures do
        expect(result).to be_success
        expect(result.payload[:redirect_to]).to eq(redirect_url)
      end

      it 'sends the correct gRPC request' do
        result

        expect(grpc_client).to have_received(:accept_login_challenge).with(
          challenge: challenge,
          subject: user.id.to_s,
          name: user.name,
          email: user.email
        )
      end
    end

    context 'when the gRPC client raises a RequestError' do
      before do
        allow(grpc_client).to receive(:accept_login_challenge)
          .and_raise(Authn::IamService::GrpcClient::RequestError, 'Failed to connect to IAM service')
      end

      include_examples 'iam service error response with user',
        reason: :service_unavailable,
        message: 'Failed to connect to IAM service'
    end

    context 'when the response is missing redirect_to' do
      let(:response) { ::Auth::V1::LoginServiceAcceptResponse.new(redirect_to: '') }

      include_examples 'iam service error response with user',
        reason: :invalid_response,
        message: 'IAM login accept response missing redirect_to'
    end

    context 'when redirect_to points to a different host' do
      let(:response) { ::Auth::V1::LoginServiceAcceptResponse.new(redirect_to: 'https://untrusted.com/oauth2/authorize') }

      include_examples 'iam service error response with user',
        reason: :invalid_redirect_url,
        message: 'IAM login accept response contains invalid redirect URL'
    end
  end
end
