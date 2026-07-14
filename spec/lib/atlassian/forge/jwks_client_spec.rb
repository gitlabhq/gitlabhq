# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Atlassian::Forge::JwksClient, :use_clean_rails_redis_caching, feature_category: :integrations do
  subject(:client) { described_class.new }

  let(:private_key) { OpenSSL::PKey::RSA.new(2048) }
  let(:kid) { 'forge-test-key-id' }
  let(:jwk) { JWT::JWK.new(private_key, { use: 'sig', kid: kid }) }
  let(:jwks_response) { { 'keys' => [jwk.export] } }
  let(:cache_key) { "atlassian:forge:jwks:#{described_class::JWKS_URL}" }
  let(:headers) { { 'cache-control' => 'max-age=3600' } }

  let(:successful_response) do
    build_response(success: true, headers: headers, parsed_response: jwks_response, code: 200)
  end

  describe '#verification_key_for' do
    context 'when kid is blank' do
      it 'raises ArgumentError' do
        expect { client.verification_key_for(nil) }.to raise_error(ArgumentError, /kid cannot be blank/)
        expect { client.verification_key_for('') }.to raise_error(ArgumentError, /kid cannot be blank/)
      end
    end

    context 'when keyset is not cached' do
      before do
        allow(Gitlab::HTTP).to receive(:get).and_return(successful_response)
      end

      it 'fetches the JWKS over HTTP and returns the public key' do
        key = client.verification_key_for(kid)

        expect(key).to be_a(OpenSSL::PKey::RSA)
        expect(Gitlab::HTTP).to have_received(:get).with(described_class::JWKS_URL, timeout: 5).once
      end

      it 'caches the keyset (second lookup makes no HTTP call)' do
        client.verification_key_for(kid)
        client.verification_key_for(kid)

        expect(Gitlab::HTTP).to have_received(:get).once
      end
    end

    context 'when the key is not in the keyset' do
      before do
        allow(Gitlab::HTTP).to receive(:get).and_return(successful_response)
      end

      it 'logs and raises KeyNotFoundError' do
        expect(Gitlab::AuthLogger).to receive(:error).with(
          message: 'Forge JWKS key not found', forge_jwks_kid: 'missing-kid'
        )

        expect { client.verification_key_for('missing-kid') }
          .to raise_error(described_class::KeyNotFoundError, /not found in Forge JWKS/)
      end
    end

    context 'when the network request fails' do
      before do
        allow(Gitlab::HTTP).to receive(:get).and_raise(Errno::ECONNREFUSED)
        allow(Gitlab::ErrorTracking).to receive(:track_exception)
      end

      it 'tracks the exception and raises JwksFetchFailedError' do
        expect(Gitlab::ErrorTracking).to receive(:track_exception).with(instance_of(Errno::ECONNREFUSED))

        expect { client.verification_key_for(kid) }
          .to raise_error(described_class::JwksFetchFailedError, /Failed to connect/)
      end
    end

    context 'when the HTTP response is unsuccessful' do
      before do
        allow(Gitlab::HTTP).to receive(:get)
          .and_return(build_response(success: false, parsed_response: nil, code: 503))
      end

      it 'raises JwksFetchFailedError with the status code' do
        expect { client.verification_key_for(kid) }
          .to raise_error(described_class::JwksFetchFailedError, /HTTP 503/)
      end
    end

    context 'when the JWKS is malformed' do
      before do
        allow(Gitlab::HTTP).to receive(:get).and_return(
          build_response(success: true, parsed_response: { 'keys' => [{ 'invalid' => 'data' }] }, code: 200)
        )
        allow(Gitlab::ErrorTracking).to receive(:track_exception)
      end

      it 'raises JwksFetchFailedError' do
        expect { client.verification_key_for(kid) }
          .to raise_error(described_class::JwksFetchFailedError, /invalid format/)
      end
    end
  end

  def build_response(success: true, headers: {}, parsed_response: nil, code: 200)
    instance_double(
      HTTParty::Response,
      success?: success,
      headers: headers,
      parsed_response: parsed_response,
      code: code
    )
  end
end
