# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Authn::IamService::JwtValidationService, feature_category: :system_access do
  include_context 'with IAM authentication setup'

  let_it_be(:user) { create(:user) }
  let(:service) { described_class.new(token: token_string, audience: iam_audience) }

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
      expect(Gitlab::AuthLogger).to receive(:warn).with(
        message: 'IAM JWT validation failed',
        error_message: message.is_a?(String) ? message : anything
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
          create_iam_jwt(user: user, issuer: 'https://evil.com', private_key: private_key, kid: kid)
        end

        include_examples 'token validation error', message: 'Invalid token issuer'
      end

      context 'when token has invalid audience' do
        let(:token_string) do
          create_iam_jwt(user: user, issuer: iam_issuer, private_key: private_key, kid: kid, aud: 'wrong')
        end

        include_examples 'token validation error', message: 'Invalid token audience'
      end

      context 'when signature verification fails' do
        # Override the shared_context's JWKS stub for signature verification tests
        before do
          WebMock.reset!
        end

        context 'when IAM service has rotated keys (retry succeeds)' do
          let(:old_key) { OpenSSL::PKey::RSA.new(2048) }
          let(:new_key) { OpenSSL::PKey::RSA.new(2048) }
          let(:token_string) do
            create_iam_jwt(user: user, issuer: iam_issuer, private_key: new_key, kid: kid)
          end

          before do
            stub_iam_jwks_key_rotation(old_key: old_key, new_key: new_key)
          end

          it 'succeeds after refreshing keys' do
            expect(result).to be_success
          end
        end

        context 'when signature verification fails after retry' do
          let(:wrong_key) { OpenSSL::PKey::RSA.new(2048) }
          let(:token_string) do
            create_iam_jwt(user: user, issuer: iam_issuer, private_key: wrong_key, kid: kid)
          end

          before do
            stub_iam_jwks_endpoint(private_key.public_key)
          end

          it 'returns error after exhausting retry attempts' do
            expect(result).to be_error
            expect(result.reason).to eq(:invalid_token)
            expect(result.message).to match(/Signature verification failed/)
          end

          it 'logs the validation failure' do
            expect(Gitlab::AuthLogger).to receive(:warn).with(
              message: 'IAM JWT validation failed',
              error_message: anything
            ).once

            result
          end

          it 'refreshes keys exactly once before giving up' do
            jwks_client = instance_double(Authn::IamService::JwksClient)
            allow(service).to receive(:jwks_client).and_return(jwks_client)
            allow(jwks_client).to receive(:fetch_keys).and_return(
              JWT::JWK::Set.new(JWT::JWK.new(private_key.public_key, { use: 'sig', kid: kid }))
            )
            expect(jwks_client).to receive(:refresh_keys).once

            result
          end

          it 'does not attempt a third decode after second failure' do
            decode_count = 0
            allow_next_instance_of(described_class) do |instance|
              allow(instance).to receive(:decode_token).and_wrap_original do |method|
                decode_count += 1
                method.call
              end
            end

            result

            expect(decode_count).to eq(2)
          end

          # Coverage test: Ensures the "raise if @retry_attempted" guard clause is fully covered.
          # The behavior is already tested above, but undercoverage script doesn't detect it.
          it 'raises immediately when retry has already been attempted' do
            test_service = described_class.new(token: token_string, audience: iam_audience)
            test_service.instance_variable_set(:@retry_attempted, true)

            expect { test_service.send(:decode_with_retry) }.to raise_error(JWT::VerificationError)
          end
        end
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

        include_examples 'returns error', reason: :service_unavailable, message: /Cannot connect to IAM service/

        it 'does not log the failure' do
          expect(Gitlab::AuthLogger).not_to receive(:warn)
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
          expect(Gitlab::AuthLogger).not_to receive(:warn)
          result
        end

        # Coverage test: Ensures the endpoint method's nil check is covered.
        # This test ensures the endpoint method's branch is explicitly exercised.
        it 'raises ConfigurationError from endpoint method when URL is nil' do
          jwks_client = Authn::IamService::JwksClient.new

          expect do
            jwks_client.send(:endpoint)
          end.to raise_error(Authn::IamService::JwksClient::ConfigurationError, /not configured/)
        end
      end
    end
  end
end
