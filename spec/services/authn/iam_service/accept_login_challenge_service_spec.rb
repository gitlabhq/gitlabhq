# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Authn::IamService::AcceptLoginChallengeService, feature_category: :system_access do
  let_it_be(:user) { create(:user) }
  let(:iam_secret) { 'test-secret-token' }

  let(:iam_service_url) { 'https://iam.example.com' }
  let(:challenge) { 'a' * 64 }
  let(:redirect_url) { "#{iam_service_url}/oauth2/authorize?client_id=test-app&login_verifier=#{'b' * 64}" }

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

    shared_examples 'returns IAM accept error' do |reason:, message:|
      it 'returns an error response and logs the failure', :aggregate_failures do
        allow(Gitlab::AuthLogger).to receive(:error)

        result

        expect(result).to be_error
        expect(result.reason).to eq(reason)
        expect(result.message).to eq(message)
        expect(Gitlab::AuthLogger).to have_received(:error).with(hash_including(Labkit::Fields::GL_USER_ID => user.id))
      end
    end

    context 'when the IAM service accepts the challenge' do
      it 'returns a success response with the redirect URL' do
        expect(result).to be_success
        expect(result.payload[:redirect_to]).to eq(redirect_url)
      end

      it 'sends the correct HTTP PUT request to the IAM service' do
        result

        expect(Gitlab::HTTP).to have_received(:put).with(
          "#{iam_service_url}#{described_class::ACCEPT_PATH}?challenge=#{challenge}",
          hash_including(
            body: { id: user.id.to_s, subject: user.id.to_s, name: user.name, email: user.email }.to_json,
            headers: { 'Content-Type' => 'application/json',
                       Authn::IamAuthService::IAM_AUTH_TOKEN_HEADER => iam_secret },
            timeout: described_class::TIMEOUT_SECONDS
          )
        )
      end
    end

    context 'when the IAM service returns unauthorized' do
      let(:http_response) do
        instance_double(Gitlab::HTTP::Response, success?: false, code: 401,
          body: { error: 'Unauthorized' }.to_json)
      end

      include_examples 'returns IAM accept error',
        reason: :iam_request_failed,
        message: 'IAM login accept failed: HTTP 401'
    end

    context 'when the IAM service rejects the challenge' do
      let(:http_response) do
        instance_double(Gitlab::HTTP::Response, success?: false, code: 400,
          body: { error: 'Failed to accept login challenge' }.to_json)
      end

      include_examples 'returns IAM accept error',
        reason: :iam_request_failed,
        message: 'IAM login accept failed: HTTP 400'
    end

    context 'when the IAM service returns a server error' do
      let(:http_response) do
        instance_double(Gitlab::HTTP::Response, success?: false, code: 500, body: 'Internal Server Error')
      end

      include_examples 'returns IAM accept error',
        reason: :iam_request_failed,
        message: 'IAM login accept failed: HTTP 500'
    end

    context 'when the response is missing redirect_to' do
      let(:http_response) do
        instance_double(Gitlab::HTTP::Response, success?: true, code: 200,
          body: { some_other_field: 'value' }.to_json)
      end

      include_examples 'returns IAM accept error',
        reason: :invalid_response,
        message: 'IAM login accept response missing redirect_to'
    end

    context 'when request success but response body is nil' do
      let(:http_response) do
        instance_double(Gitlab::HTTP::Response, success?: true, code: 200, body: nil)
      end

      include_examples 'returns IAM accept error',
        reason: :invalid_response,
        message: 'IAM login accept response missing redirect_to'
    end

    context 'when redirect_to points to a different host' do
      let(:http_response) do
        instance_double(Gitlab::HTTP::Response, success?: true, code: 200,
          body: { redirect_to: 'https://untrusted.com/oauth2/authorize' }.to_json)
      end

      include_examples 'returns IAM accept error',
        reason: :invalid_redirect_url,
        message: 'IAM login accept response contains invalid redirect URL'
    end

    context 'when redirect_to is not a valid URL' do
      let(:http_response) do
        instance_double(Gitlab::HTTP::Response, success?: true, code: 200,
          body: { redirect_to: 'not-a-url' }.to_json)
      end

      include_examples 'returns IAM accept error',
        reason: :invalid_redirect_url,
        message: 'IAM login accept response contains invalid redirect URL'
    end

    context 'when redirect_to is a malformed URI that cannot be parsed' do
      let(:http_response) do
        instance_double(Gitlab::HTTP::Response, success?: true, code: 200,
          body: { redirect_to: "https://iam.example.com /oauth2/authorize?login_verifier=abc123" }.to_json)
      end

      include_examples 'returns IAM accept error',
        reason: :invalid_redirect_url,
        message: 'IAM login accept response contains invalid redirect URL'
    end

    context 'when redirect_to has matching host but different port' do
      let(:http_response) do
        instance_double(Gitlab::HTTP::Response, success?: true, code: 200,
          body: { redirect_to: "https://iam.example.com:9999/oauth2/authorize?client_id=test-app&login_verifier=#{'b' * 64}" }
                  .to_json)
      end

      include_examples 'returns IAM accept error',
        reason: :invalid_redirect_url,
        message: 'IAM login accept response contains invalid redirect URL'
    end

    context 'when redirect_to uses http scheme' do
      let(:iam_service_url) { 'http://iam.example.com' }
      let(:http_response) do
        instance_double(Gitlab::HTTP::Response, success?: true, code: 200,
          body: { redirect_to: "#{iam_service_url}/oauth2/authorize?login_verifier=abc" }.to_json)
      end

      it 'rejects in non-development environment' do
        allow(Rails.env).to receive(:development?).and_return(false)

        expect(result).to be_error
        expect(result.reason).to eq(:invalid_redirect_url)
      end

      it 'accepts in development environment' do
        allow(Rails.env).to receive(:development?).and_return(true)

        expect(result).to be_success
      end
    end

    context 'when the response body is invalid JSON' do
      before do
        allow(Gitlab::HTTP).to receive(:put).and_raise(JSON::ParserError)
      end

      it 'returns a service_unavailable error and tracks the exception', :aggregate_failures do
        expect(Gitlab::ErrorTracking).to receive(:track_exception).with(instance_of(JSON::ParserError))

        expect(result).to be_error
        expect(result.reason).to eq(:service_unavailable)
        expect(result.message).to eq('Failed to connect to IAM service')
      end
    end

    context 'when the IAM service is not configured' do
      before do
        allow(Authn::IamAuthService).to receive(:url)
          .and_raise(Authn::IamAuthService::ConfigurationError, 'IAM service is not configured')
      end

      it 'returns a service_unavailable error' do
        expect(result).to be_error
        expect(result.reason).to eq(:service_unavailable)
        expect(result.message).to eq('IAM service is not configured')
      end
    end

    context 'when a network error occurs' do
      before do
        allow(Gitlab::HTTP).to receive(:put).and_raise(Errno::ECONNREFUSED)
      end

      it 'returns a service_unavailable error and tracks the exception', :aggregate_failures do
        expect(Gitlab::ErrorTracking).to receive(:track_exception).with(instance_of(Errno::ECONNREFUSED))

        expect(result).to be_error
        expect(result.reason).to eq(:service_unavailable)
        expect(result.message).to eq('Failed to connect to IAM service')
      end
    end
  end
end
