# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Authn::IamService::RejectConsentChallengeService, feature_category: :system_access do
  let_it_be(:user) { create(:user) }

  let(:iam_service_url) { 'https://iam.example.com' }
  let(:iam_secret) { 'test-secret-token' }
  let(:challenge) { 'a' * 64 }
  let(:redirect_url) { "#{iam_service_url}/oauth2/authorize?error=access_denied" }

  let(:service) { described_class.new(challenge: challenge, user: user) }

  subject(:result) { service.execute }

  before do
    allow(Authn::IamAuthService).to receive_messages(
      url: iam_service_url,
      secret: iam_secret
    )
  end

  describe '#execute' do
    let(:http_response) do
      instance_double(Gitlab::HTTP::Response, success?: true, code: 200,
        body: { redirect_to: redirect_url }.to_json)
    end

    before do
      allow(Gitlab::HTTP).to receive(:put).and_return(http_response)
    end

    context 'when the IAM service accepts the rejection' do
      it 'returns a success response with the redirect URL', :aggregate_failures do
        expect(result).to be_success
        expect(result.payload[:redirect_to]).to eq(redirect_url)
      end

      it 'sends the correct HTTP PUT request to the IAM service' do
        result

        expect(Gitlab::HTTP).to have_received(:put).with(
          "#{iam_service_url}#{described_class::REJECT_PATH}?challenge=#{challenge}",
          hash_including(
            body: {
              error: 'access_denied',
              error_description: 'The user denied the request'
            }.to_json,
            headers: { 'Content-Type' => 'application/json',
                       Authn::IamAuthService::IAM_AUTH_TOKEN_HEADER => iam_secret },
            timeout: Authn::IamService::HttpClient::TIMEOUT_SECONDS
          )
        )
      end
    end

    context 'when the IAM service returns an HTTP error' do
      let(:http_response) do
        instance_double(Gitlab::HTTP::Response, success?: false, code: 400,
          body: { error: 'Invalid challenge' }.to_json)
      end

      include_examples 'iam service error response with user',
        reason: :iam_request_failed,
        message: 'IAM consent reject failed: HTTP 400'
    end

    context 'when the response is missing redirect_to' do
      let(:http_response) do
        instance_double(Gitlab::HTTP::Response, success?: true, code: 200,
          body: { some_other_field: 'value' }.to_json)
      end

      include_examples 'iam service error response with user',
        reason: :invalid_response,
        message: 'IAM consent reject response missing redirect_to'
    end

    context 'when request succeeds but response body is nil' do
      let(:http_response) do
        instance_double(Gitlab::HTTP::Response, success?: true, code: 200, body: nil)
      end

      include_examples 'iam service error response with user',
        reason: :invalid_response,
        message: 'IAM consent reject response missing redirect_to'
    end

    context 'when redirect_to points to a different host' do
      let(:http_response) do
        instance_double(Gitlab::HTTP::Response, success?: true, code: 200,
          body: { redirect_to: 'https://untrusted.com/oauth2/authorize' }.to_json)
      end

      include_examples 'iam service error response with user',
        reason: :invalid_redirect_url,
        message: 'IAM consent reject response contains invalid redirect URL'
    end

    include_examples 'iam service transport failure', http_method: :put
  end
end
