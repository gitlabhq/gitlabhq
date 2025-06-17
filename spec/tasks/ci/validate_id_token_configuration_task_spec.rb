# frozen_string_literal: true

require 'spec_helper'
require_relative '../../../lib/tasks/ci/validate_id_token_configuration_task'

RSpec.describe Tasks::Ci::ValidateIdTokenConfigurationTask, :silence_stdout, feature_category: :secrets_management do
  let(:run_task) { described_class.new.validate! }
  let(:rsa_key) { OpenSSL::PKey.generate_key('RSA') }
  let(:jwk) { rsa_key.public_key.to_jwk }
  let(:jwks) { { keys: [jwk].map { |jwk| jwk.merge(use: 'sig', alg: 'RS256') } } }
  let(:issuer_url) { 'https://gitlab.example.com' }
  let(:open_id_configuration_url) { "#{issuer_url}/.well-known/openid-configuration" }
  let(:jwks_url) { "#{issuer_url}/oauth/discovery/keys" }
  let(:open_id_configuration) do
    {
      issuer: issuer_url,
      jwks_uri: jwks_url,
      scopes_supported: ['api'],
      response_types_supported: ['code'],
      response_modes_supported: ['query'],
      grant_types_supported: %w[authorization_code refresh_token],
      subject_types_supported: ['public'],
      id_token_signing_alg_values_supported: ['RS256'],
      claim_types_supported: ['normal'],
      claims_supported: %w[
        iss
        sub
        aud
        exp
        iat
        sub_legacy
        name
        nickname
        preferred_username
        email
        email_verified
      ]
    }
  end

  let(:invalid_open_id_configuration) do
    {
      issuer: 'https://invalid.example.com',
      jwks_uri: jwks_url,
      id_token_signing_alg_values_supported: ['RS256']
    }
  end

  before do
    create(:ci_build)
    stub_application_setting(ci_jwt_signing_key: rsa_key.to_s)
    allow(::Gitlab.config.ci_id_tokens).to receive(:issuer_url).and_return(issuer_url)
    allow(::Gitlab::HTTP).to receive(:get).with(open_id_configuration_url).and_return(instance_double(
      HTTParty::Response, body: open_id_configuration.to_json))
    allow(::Gitlab::HTTP).to receive(:get).with(jwks_url).and_return(instance_double(
      HTTParty::Response, body: jwks.to_json))
  end

  describe '#validate!' do
    context 'when the configuration is valid' do
      it 'validates the ID token configuration and outputs success message' do
        expect { run_task }
          .to output("\n\n\n****** CI ID token configuration is valid ******\n\n\n").to_stdout
      end
    end

    context 'when validation fails' do
      context 'when incorrect issuer URL' do
        before do
          allow(::Gitlab::HTTP).to receive(:get).with(open_id_configuration_url).and_return(instance_double(
            HTTParty::Response, body: invalid_open_id_configuration.to_json))
        end

        it 'displays the correct error message' do
          error_message = "\n\n\n****** CI ID token configuration validation failed : " \
            "issuer: value incorrectly configured: expected https://gitlab.example.com, " \
            "got https://invalid.example.com ******\n\n\n"
          expect { run_task }
            .to output(error_message).to_stdout
        end
      end

      context 'when the OpenID configuration cannot be retrieved' do
        before do
          allow(::Gitlab::HTTP).to receive(:get).with(open_id_configuration_url)
            .and_raise(Gitlab::HTTP::Error.new('Network error'))
        end

        it 'displays the correct error message' do
          expect { run_task }
            .to output(/Error while accessing OpenID configuration/).to_stdout
        end
      end

      context 'when openID configuration JSON is invalid' do
        before do
          allow(::Gitlab::HTTP).to receive(:get).with(open_id_configuration_url)
            .and_return(instance_double(HTTParty::Response, body: 'invalid json'))
        end

        it 'displays the correct error message' do
          expect { run_task }
            .to output(/Invalid JSON response/).to_stdout
        end
      end

      context 'when the JWKS cannot be retrieved' do
        before do
          allow(::Gitlab::HTTP).to receive(:get).with(jwks_url)
            .and_raise(Gitlab::HTTP::Error.new('Network error'))
        end

        it 'displays the correct error message' do
          expect { run_task }
            .to output(/Error while accessing JWKS URI/).to_stdout
        end
      end

      context 'when JWKS JSON is invalid' do
        before do
          allow(::Gitlab::HTTP).to receive(:get).with(jwks_url)
            .and_return(instance_double(HTTParty::Response, body: 'invalid json'))
        end

        it 'displays the correct error message' do
          expect { run_task }
            .to output(/Invalid JSON response/).to_stdout
        end
      end

      context 'when the ID token cannot be verified' do
        before do
          allow(JWT).to receive(:decode).with(anything,
            nil, false).and_call_original # Initial decoding without verification
          allow(JWT).to receive(:decode).with(anything, anything, true,
            anything).and_raise(JWT::DecodeError.new('Invalid token'))
        end

        it 'displays the correct error message' do
          expect { run_task }
            .to output(/JWT verification failed: Invalid token/).to_stdout
        end
      end

      context 'when runtime errors occur' do
        before do
          allow(JWT).to receive(:decode).and_raise(StandardError.new('Unexpected error'))
        end

        it 'displays the correct error message' do
          expect { run_task }
            .to output(/CI ID token configuration validation failed : Unexpected error/).to_stdout
        end
      end
    end
  end
end
