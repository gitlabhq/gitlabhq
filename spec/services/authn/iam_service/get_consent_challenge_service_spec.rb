# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Authn::IamService::GetConsentChallengeService, feature_category: :system_access do
  let(:iam_service_url) { 'https://iam.example.com' }
  let(:iam_secret) { 'test-secret-token' }
  let(:challenge) { 'a' * 64 }

  let(:service) { described_class.new(challenge: challenge) }

  subject(:result) { service.execute }

  before do
    allow(Authn::IamAuthService).to receive_messages(
      url: iam_service_url,
      secret: iam_secret
    )
  end

  describe '#execute' do
    let(:consent_response_body) do
      {
        skip: false,
        subject: '123',
        requested_scope: %w[openid profile],
        client: { 'client_id' => 'test-app', 'client_name' => 'Test App' }
      }
    end

    let(:http_response) do
      instance_double(Gitlab::HTTP::Response, success?: true, code: 200,
        body: consent_response_body.to_json)
    end

    before do
      allow(Gitlab::HTTP).to receive(:get).and_return(http_response)
    end

    context 'when the IAM service returns consent details' do
      it 'returns a success response with the consent payload', :aggregate_failures do
        expect(result).to be_success
        expect(result.payload[:skip]).to be(false)
        expect(result.payload[:subject]).to eq('123')
        expect(result.payload[:requested_scope]).to eq(%w[openid profile])
        expect(result.payload[:client]).to eq({ 'client_id' => 'test-app', 'client_name' => 'Test App' })
      end

      it 'sends the correct HTTP GET request to the IAM service' do
        result

        expect(Gitlab::HTTP).to have_received(:get).with(
          "#{iam_service_url}#{described_class::CONSENT_REQUEST_PATH}?consent_challenge=#{challenge}",
          hash_including(
            headers: { 'Content-Type' => 'application/json',
                       Authn::IamAuthService::IAM_AUTH_TOKEN_HEADER => iam_secret },
            timeout: Authn::IamService::HttpClient::TIMEOUT_SECONDS
          )
        )
      end
    end

    context 'when skip is true' do
      let(:consent_response_body) do
        {
          skip: true,
          subject: '123',
          requested_scope: %w[openid],
          client: { 'client_id' => 'test-app' }
        }
      end

      it 'returns skip as true in the payload', :aggregate_failures do
        expect(result).to be_success
        expect(result.payload[:skip]).to be(true)
      end
    end

    context 'when the IAM service returns an HTTP error' do
      let(:http_response) do
        instance_double(Gitlab::HTTP::Response, success?: false, code: 400,
          body: { error: 'Invalid challenge' }.to_json)
      end

      include_examples 'iam service error response',
        reason: :iam_request_failed,
        message: 'IAM consent request failed: HTTP 400'
    end

    context 'when the response body is nil' do
      let(:http_response) do
        instance_double(Gitlab::HTTP::Response, success?: true, code: 200, body: nil)
      end

      include_examples 'iam service error response',
        reason: :invalid_response,
        message: 'IAM consent request response has invalid body'
    end

    include_examples 'iam service transport failure', http_method: :get
  end
end
