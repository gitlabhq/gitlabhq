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
      context 'with valid token' do
        let(:token_string) do
          create_iam_jwt(user: user, scopes: 'api read_repository', issuer: iam_issuer,
            private_key: private_key, kid: kid)
        end

        it 'returns a success ServiceResponse with payload and scopes' do
          expect(result).to be_a(ServiceResponse)
          expect(result).to be_success
          expect(result.payload[:payload]['sub']).to eq("user:#{user.id}")
          expect(result.payload[:scopes]).to contain_exactly('api', 'read_repository')
        end
      end

      context 'with valid token without scopes' do
        let(:token_string) do
          create_iam_jwt(user: user, scopes: nil, issuer: iam_issuer,
            private_key: private_key, kid: kid)
        end

        it 'returns success with empty scopes array' do
          expect(result).to be_a(ServiceResponse)
          expect(result).to be_success
          expect(result.payload[:scopes]).to eq([])
        end
      end

      context 'with scopes containing whitespace' do
        let(:token_string) do
          create_iam_jwt(user: user, scopes: '  api   read_repository  ', issuer: iam_issuer,
            private_key: private_key, kid: kid)
        end

        it 'returns success with trimmed scopes' do
          expect(result).to be_a(ServiceResponse)
          expect(result).to be_success
          expect(result.payload[:scopes]).to contain_exactly('api', 'read_repository')
        end
      end

      context 'with expired token' do
        let(:token_string) do
          create_iam_jwt(user: user, expires_at: 1.hour.ago, issuer: iam_issuer,
            private_key: private_key, kid: kid)
        end

        include_examples 'token validation error', message: 'Token has expired'
      end

      context 'with invalid issuer' do
        let(:token_string) do
          create_iam_jwt(user: user, issuer: 'https://evil.com', private_key: private_key, kid: kid)
        end

        include_examples 'token validation error', message: 'Invalid token issuer'
      end

      context 'with invalid audience' do
        let(:token_string) do
          create_iam_jwt(user: user, issuer: iam_issuer, private_key: private_key, kid: kid, aud: 'wrong')
        end

        include_examples 'token validation error', message: 'Invalid token audience'
      end

      context 'with invalid signature' do
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
            # Simulate key rotation: first call returns old key, second call returns new key
            old_jwks = { 'keys' => [JWT::JWK.new(old_key.public_key, { use: 'sig', kid: kid }).export] }
            new_jwks = { 'keys' => [JWT::JWK.new(new_key.public_key, { use: 'sig', kid: kid }).export] }

            stub_request(:get, "#{iam_service_url}/.well-known/jwks.json")
              .to_return(
                { status: 200, body: old_jwks.to_json, headers: { 'Content-Type' => 'application/json' } },
                { status: 200, body: new_jwks.to_json, headers: { 'Content-Type' => 'application/json' } }
              )
          end

          it 'succeeds after refreshing keys' do
            expect(result).to be_success
          end
        end

        context 'when token has invalid signature (retry also fails)' do
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
            jwks_client = service.send(:jwks_client)
            expect(jwks_client).to receive(:refresh_keys).once.and_call_original

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
            test_service = described_class.new(token: token_string)
            test_service.instance_variable_set(:@retry_attempted, true)

            expect { test_service.send(:decode_with_retry) }.to raise_error(JWT::VerificationError)
          end
        end
      end

      context 'with malformed token' do
        let(:token_string) { 'not-a-valid-jwt' }

        include_examples 'token validation error', message: /Invalid token format/
      end

      context 'with missing required claim' do
        let(:token_string) do
          create_iam_jwt(user: user, issuer: iam_issuer, private_key: private_key, kid: kid,
            exclude_claims: ['jti'])
        end

        include_examples 'token validation error', message: /Invalid token format/
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
