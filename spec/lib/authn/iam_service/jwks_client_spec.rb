# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Authn::IamService::JwksClient, :use_clean_rails_redis_caching, feature_category: :system_access do
  subject(:client) { described_class.new }

  let(:service_url) { 'https://iam.example.com' }
  let(:jwks_response) { { 'keys' => [JWT::JWK.new(OpenSSL::PKey::RSA.new(2048)).export] } }
  let(:success_response) do
    instance_double(HTTParty::Response, success?: true, parsed_response: jwks_response,
      headers: { "Cache-Control" => "public, max-age=3600, must-revalidate" })
  end

  before do
    allow(Gitlab.config.authn.iam_service).to receive_messages(
      enabled: true,
      url: service_url,
      audience: 'gitlab-rails'
    )
    allow(Gitlab::HTTP).to receive(:get).and_return(success_response)
  end

  describe '#fetch_keys', :clean_gitlab_redis_cache do
    it 'fetches JWKS from IAM service' do
      client.fetch_keys
      client.fetch_keys

      expect(Gitlab::HTTP).to have_received(:get).with("#{service_url}/.well-known/jwks.json", timeout: 5).once
    end

    it 'returns a JWT::JWK::Set instance with the correct keys' do
      result = client.fetch_keys

      keys = result.keys
      expect(result).to be_a(JWT::JWK::Set)
      expect(keys.length).to eq(1)
      expect(keys.first).to be_a(JWT::JWK::RSA)
      expect(keys.first.export).to eq(jwks_response['keys'].first)
    end

    it 'raises error when HTTP request fails' do
      allow(Gitlab::HTTP).to receive(:get).and_return(instance_double(HTTParty::Response, success?: false, code: 500))

      expect do
        client.fetch_keys
      end.to raise_error(Authn::IamService::JwksClient::JwksFetchFailedError, /Failed to fetch JWKS/)
    end

    it 'tracks and raises error on connection failure' do
      allow(Gitlab::HTTP).to receive(:get).and_raise(Errno::ECONNREFUSED)

      expect(Gitlab::ErrorTracking).to receive(:track_exception).with(instance_of(Errno::ECONNREFUSED))
      expect { client.fetch_keys }.to raise_error(Authn::IamService::JwksClient::JwksFetchFailedError, /Cannot connect/)
    end

    it 'raises error when service URL not configured' do
      allow(Gitlab.config.authn.iam_service).to receive(:url).and_return(nil)

      expect { client.fetch_keys }.to raise_error(Authn::IamService::JwksClient::ConfigurationError, /not configured/)
    end

    it 'raises error when format is invalid' do
      allow(Gitlab::HTTP).to receive(:get).and_return(instance_double(HTTParty::Response, success?: true,
        parsed_response: 'invalid'))

      expect do
        client.fetch_keys
      end.to raise_error(Authn::IamService::JwksClient::JwksFetchFailedError, /malformed key data/)
    end
  end

  describe '#refresh_keys' do
    it 'clears cache before fetching' do
      expect(Rails.cache).to receive(:delete)
      expect(Gitlab::HTTP).to receive(:get).and_return(success_response)

      client.refresh_keys
    end
  end

  describe 'when cache-control header is present' do
    it 'extracts max-age from cache-control header' do
      response = instance_double(HTTParty::Response, headers: { 'cache-control' => 'max-age=3600' })

      expect(client.send(:parse_cache_ttl, response)).to eq(3600.seconds)
    end

    it 'handles capitalized Cache-Control header' do
      response = instance_double(HTTParty::Response, headers: { 'Cache-Control' => 'public, max-age=7200' })

      expect(client.send(:parse_cache_ttl, response)).to eq(7200.seconds)
    end

    it 'returns nil when no cache-control header' do
      response = instance_double(HTTParty::Response, headers: {})

      expect(client.send(:parse_cache_ttl, response)).to be_nil
    end

    it 'returns nil when cache-control header has no max-age' do
      response = instance_double(HTTParty::Response, headers: { 'cache-control' => 'no-cache, no-store' })

      expect(client.send(:parse_cache_ttl, response)).to be_nil
    end
  end
end
