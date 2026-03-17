# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Authn::IamService::JwtValidationService, feature_category: :system_access do
  include_context 'with IAM authentication setup'

  let_it_be(:user) { create(:user) }
  let(:service) { described_class.new(token: token_string) }

  subject(:result) { service.execute }

  shared_examples 'returns error' do |reason:, message:|
    it 'returns an error ServiceResponse with correct reason and message' do
      expect(result).to be_a(ServiceResponse)
      expect(result).to be_error
      expect(result.reason).to eq(reason)

      if message.is_a?(String)
        expect(result.message).to eq(message)
      else
        expect(result.message).to match(message)
      end
    end
  end

  shared_examples 'token validation error' do |message:|
    include_examples 'returns error', reason: :invalid_token, message: message

    it 'logs the failure' do
      expect(Gitlab::AuthLogger).to receive(:error).with(
        message: 'IAM JWT validation failed',
        error: message.is_a?(String) ? message : anything
      ).once

      result
    end
  end

  describe '#execute' do
    context 'when IAM is disabled' do
      let(:token_string) { create_iam_jwt(user: user, issuer: iam_issuer, private_key: private_key, kid: kid) }

      before do
        stub_iam_service_config(enabled: false, url: iam_service_url)
      end

      include_examples 'returns error', reason: :disabled, message: 'IAM JWT authentication is disabled'

      it 'logs the authentication attempt' do
        expect(Gitlab::AuthLogger).to receive(:info).with(
          message: 'IAM JWT authentication attempt when disabled',
          reason: :disabled
        )

        result
      end
    end

    context 'when IAM is enabled' do
      context 'when token is valid' do
        let(:token_string) do
          create_iam_jwt(user: user, scopes: 'api read_repository', issuer: iam_issuer,
            private_key: private_key, kid: kid)
        end

        it 'returns a success ServiceResponse with jwt_payload' do
          expect(result).to be_a(ServiceResponse)
          expect(result).to be_success
          expect(result.payload[:jwt_payload]).to be_a(Hash)
          expect(result.payload[:jwt_payload]['sub']).to eq(user.id.to_s)
          expect(result.payload[:jwt_payload]['scope']).to eq('api read_repository')
          expect(result.payload[:jwt_payload]['jti']).to be_present
          expect(result.payload[:jwt_payload]['iss']).to eq(iam_issuer)
          expect(result.payload[:jwt_payload]['aud']).to eq(iam_audience)
          expect(result.payload[:jwt_payload]['exp']).to be_present
          expect(result.payload[:jwt_payload]['iat']).to be_present
        end
      end

      context 'when token has expired' do
        let(:token_string) do
          create_iam_jwt(user: user, expires_at: 1.hour.ago, issuer: iam_issuer,
            private_key: private_key, kid: kid)
        end

        include_examples 'token validation error', message: 'Token has expired'
      end

      context 'when token has invalid iat' do
        let(:token_string) do
          create_iam_jwt(user: user, issued_at: 1.hour.from_now, issuer: iam_issuer, private_key: private_key,
            kid: kid)
        end

        include_examples 'token validation error', message: 'Invalid token issue time'
      end

      context 'when token has invalid issuer' do
        let(:token_string) do
          create_iam_jwt(user: user, issuer: 'https://untrusted-issuer.example', private_key: private_key, kid: kid)
        end

        include_examples 'token validation error', message: 'Invalid token issuer'
      end

      context 'when token has invalid audience' do
        let(:token_string) do
          create_iam_jwt(user: user, issuer: iam_issuer, private_key: private_key, kid: kid, aud: 'wrong')
        end

        include_examples 'token validation error', message: 'Invalid token audience'
      end

      context 'when token has invalid subject' do
        let(:token_string) do
          create_iam_jwt(user: user, issuer: iam_issuer, private_key: private_key, kid: kid, sub: 'user')
        end

        include_examples 'token validation error', message: 'Invalid token subject'
      end

      context 'when token subject is not a valid positive integer string' do
        let(:token_string) do
          create_iam_jwt(user: user, issuer: iam_issuer, private_key: private_key, kid: kid, sub: '0')
        end

        include_examples 'token validation error', message: 'Invalid token subject'
      end

      context 'when signature verification fails' do
        let(:wrong_key) { OpenSSL::PKey::RSA.new(2048) }
        let(:token_string) do
          create_iam_jwt(user: user, issuer: iam_issuer, private_key: wrong_key, kid: kid)
        end

        before do
          stub_iam_jwks_endpoint(private_key.public_key)
        end

        include_examples 'token validation error', message: 'Signature verification failed'
      end

      context 'when kid is not found in JWKS' do
        let(:token_string) do
          create_iam_jwt(user: user, issuer: iam_issuer, private_key: private_key, kid: 'unknown-kid')
        end

        before do
          stub_iam_jwks_endpoint(private_key.public_key)
        end

        include_examples 'token validation error', message: 'Invalid token format'
      end

      context 'when token exceeds maximum size' do
        let(:token_string) { 'x' * (described_class::MAX_TOKEN_SIZE_BYTES + 1) }

        include_examples 'token validation error', message: 'Invalid token'
      end

      context 'when token is malformed' do
        let(:token_string) { 'not-a-valid-jwt' }

        include_examples 'token validation error', message: /Invalid token format/
      end

      context 'when token is missing required claims' do
        # Required claims: %w[sub jti exp iat iss aud scope]
        # Note: iss and aud are tested separately above with specific error messages
        let(:excluded_claim) { [] }
        let(:token_string) do
          create_iam_jwt(user: user, issuer: iam_issuer, private_key: private_key, kid: kid,
            exclude_claims: excluded_claim)
        end

        %w[sub jti exp iat scope].each do |claim|
          context "when missing #{claim} claim" do
            let(:excluded_claim) { [claim] }

            include_examples 'token validation error', message: /Invalid token format/
          end
        end
      end

      context 'when JWKS fetch fails' do
        let(:token_string) do
          create_iam_jwt(user: user, issuer: iam_issuer, private_key: private_key, kid: kid)
        end

        before do
          stub_jwks_endpoint_connection_error(url: iam_service_url, error: Errno::ECONNREFUSED)
        end

        include_examples 'returns error', reason: :service_unavailable, message: /Failed to connect to IAM service/

        it 'does not log the failure' do
          expect(Gitlab::AuthLogger).not_to receive(:error)
          result
        end
      end

      context 'when IAM service URL is not configured' do
        let(:token_string) do
          create_iam_jwt(user: user, issuer: iam_issuer, private_key: private_key, kid: kid)
        end

        before do
          allow(Gitlab.config.authn.iam_service).to receive(:url).and_return(nil)
        end

        include_examples 'returns error', reason: :service_unavailable, message: /IAM service URL is not configured/

        it 'does not log the failure' do
          expect(Gitlab::AuthLogger).not_to receive(:error)
          result
        end
      end
    end
  end
end
