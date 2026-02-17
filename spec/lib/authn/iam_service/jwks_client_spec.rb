# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Authn::IamService::JwksClient, :use_clean_rails_redis_caching, feature_category: :system_access do
  subject(:client) { described_class.new }

  let(:service_url) { 'https://iam.example.com' }
  let(:private_key) { OpenSSL::PKey::RSA.new(2048) }
  let(:kid) { 'test-key-id' }
  let(:jwk) { JWT::JWK.new(private_key, { use: 'sig', kid: kid }) }
  let(:jwks_response) { { 'keys' => [jwk.export] } }
  let(:cache_key) { "iam:jwks:#{service_url}" }

  let(:successful_response) do
    build_response(
      success: true,
      parsed_response: jwks_response,
      code: 200
    )
  end

  before do
    allow(Gitlab.config.authn.iam_service).to receive_messages(
      enabled: true,
      url: service_url,
      audience: 'gitlab-rails'
    )
  end

  describe '#verification_key_for' do
    context 'when kid is blank' do
      it 'raises ArgumentError' do
        expect { client.verification_key_for(nil) }.to raise_error(ArgumentError, /kid cannot be blank/)
        expect { client.verification_key_for('') }.to raise_error(ArgumentError, /kid cannot be blank/)
      end
    end

    context 'when keyset is not in cache' do
      before do
        allow(Gitlab::HTTP).to receive(:get).and_return(successful_response)
      end

      it 'fetches from HTTP and returns the verification key' do
        key = client.verification_key_for(kid)

        expect(key).to be_a(OpenSSL::PKey::RSA)
        expect(Gitlab::HTTP).to have_received(:get).once
      end

      it 'uses the cache TTL from configuration' do
        allow(Gitlab.config.authn.iam_service).to receive(:jwks_cache_ttl).and_return(1800)

        expect(Rails.cache).to receive(:fetch)
                                 .with(cache_key, hash_including(expires_in: 1800, race_condition_ttl: 5.seconds))
                                 .and_call_original

        client.verification_key_for(kid)
      end
    end

    context 'when key is found in cache' do
      before do
        Rails.cache.write(cache_key, JWT::JWK::Set.new(jwks_response))
        allow(Gitlab::HTTP).to receive(:get)
      end

      it 'returns the key without making HTTP request' do
        key = client.verification_key_for(kid)

        expect(key).to be_a(OpenSSL::PKey::RSA)
        expect(Gitlab::HTTP).not_to have_received(:get)
      end
    end

    context 'when keyset contains multiple keys' do
      let(:other_key) { OpenSSL::PKey::RSA.new(2048) }
      let(:other_kid) { 'other-key-id' }
      let(:other_jwk) { JWT::JWK.new(other_key, { use: 'sig', kid: other_kid }) }
      let(:multi_key_response) do
        build_response(
          success: true,
          parsed_response: { 'keys' => [jwk.export, other_jwk.export] },
          code: 200
        )
      end

      before do
        allow(Gitlab::HTTP).to receive(:get).and_return(multi_key_response)
      end

      it 'returns the correct key matching the kid' do
        key = client.verification_key_for(other_kid)

        expect(key).to be_a(OpenSSL::PKey::RSA)
        expect(key.to_pem).to eq(other_key.public_key.to_pem)
      end
    end

    context 'when key is not found' do
      before do
        allow(Gitlab::HTTP).to receive(:get).and_return(successful_response)
      end

      it 'raises KeyNotFoundError' do
        expect { client.verification_key_for('non-existent-kid') }
          .to raise_error(described_class::KeyNotFoundError, /not found in JWKS/)
      end

      it 'logs error with kid and service URL' do
        expect(Gitlab::AuthLogger).to receive(:error).with(
          message: 'JWKS key not found',
          iam_jwks_kid: 'non-existent-kid',
          iam_jwks_service_url: service_url
        )

        expect do
          client.verification_key_for('non-existent-kid')
        end.to raise_error(described_class::KeyNotFoundError)
      end
    end

    context 'when network request fails' do
      before do
        stub_jwks_error(:network, error_class: Errno::ECONNREFUSED)
        allow(Gitlab::ErrorTracking).to receive(:track_exception)
      end

      it 'raises JwksFetchFailedError and tracks exception' do
        expect(Gitlab::ErrorTracking).to receive(:track_exception)
          .with(instance_of(Errno::ECONNREFUSED))

        expect { client.verification_key_for(kid) }
          .to raise_error(described_class::JwksFetchFailedError, /Failed to connect/)
      end
    end

    context 'when HTTP response is unsuccessful' do
      before do
        stub_jwks_error(:http_status, code: 503)
      end

      it 'raises JwksFetchFailedError with status code' do
        expect { client.verification_key_for(kid) }
          .to raise_error(described_class::JwksFetchFailedError, /HTTP 503/)
      end
    end

    context 'when JWKS response is malformed' do
      before do
        stub_jwks_error(:invalid_structure, data: { 'keys' => [{ 'invalid' => 'data' }] })
        allow(Gitlab::ErrorTracking).to receive(:track_exception)
      end

      it 'raises JwksFetchFailedError and tracks exception' do
        expect(Gitlab::ErrorTracking).to receive(:track_exception)
          .with(instance_of(JWT::JWKError))

        expect { client.verification_key_for(kid) }
          .to raise_error(described_class::JwksFetchFailedError, /invalid JWKS format/)
      end
    end

    context 'when cache is empty and fetch fails' do
      before do
        Rails.cache.clear
        allow(Gitlab::HTTP).to receive(:get).and_raise(Errno::ECONNREFUSED)
        allow(Gitlab::ErrorTracking).to receive(:track_exception)
      end

      it 'raises JwksFetchFailedError' do
        expect { client.verification_key_for(kid) }
          .to raise_error(described_class::JwksFetchFailedError, /Failed to connect/)
      end
    end

    context 'when cache TTL is invalid' do
      it 'raises ConfigurationError' do
        allow(Gitlab.config.authn.iam_service).to receive(:jwks_cache_ttl).and_return('invalid')

        expect { client.verification_key_for(kid) }
          .to raise_error(described_class::ConfigurationError, /JWKS cache TTL must be a positive number/)
      end
    end

    context 'when service URL is not configured' do
      before do
        allow(Gitlab.config.authn.iam_service).to receive(:url).and_return(nil)
      end

      it 'raises ConfigurationError' do
        expect { client.verification_key_for(kid) }
          .to raise_error(described_class::ConfigurationError, /not configured/)
      end
    end

    context 'when service URL is invalid' do
      before do
        allow(Gitlab.config.authn.iam_service).to receive(:url).and_return('not a valid url')
      end

      it 'raises ConfigurationError' do
        expect { client.verification_key_for(kid) }
          .to raise_error(described_class::ConfigurationError, /Invalid IAM service URL/)
      end
    end
  end

  describe 'backward compatibility methods' do
    before do
      allow(Gitlab::HTTP).to receive(:get).and_return(successful_response)
    end

    describe '#fetch_keys' do
      it 'returns JWT::JWK::Set from cache' do
        keys = client.fetch_keys
        expect(keys).to be_a(JWT::JWK::Set)
      end
    end

    describe '#refresh_keys' do
      it 'returns refreshed JWT::JWK::Set' do
        keys = client.refresh_keys
        expect(keys).to be_a(JWT::JWK::Set)
      end

      it 'forces a cache refresh' do
        client.fetch_keys
        expect(Gitlab::HTTP).to have_received(:get).once

        client.refresh_keys
        expect(Gitlab::HTTP).to have_received(:get).twice
      end
    end
  end

  def stub_jwks_error(scenario, **options)
    case scenario
    when :network
      allow(Gitlab::HTTP).to receive(:get).and_raise(options[:error_class])
    when :http_status
      response = build_response(
        success: false,
        parsed_response: nil,
        code: options[:code]
      )
      allow(Gitlab::HTTP).to receive(:get).and_return(response)
    when :invalid_structure
      response = build_response(
        success: true,
        parsed_response: options[:data],
        code: 200
      )
      allow(Gitlab::HTTP).to receive(:get).and_return(response)
    end
  end

  def build_response(success: true, parsed_response: nil, code: 200)
    instance_double(
      HTTParty::Response,
      success?: success,
      parsed_response: parsed_response,
      code: code
    )
  end
end
