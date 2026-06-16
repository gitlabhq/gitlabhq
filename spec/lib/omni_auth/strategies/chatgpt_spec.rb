# frozen_string_literal: true

require 'spec_helper'

RSpec.describe OmniAuth::Strategies::Chatgpt, feature_category: :system_access do
  subject(:strategy) { described_class.new({}) }

  let(:raw_info) do
    {
      'sub' => 'auth0|abc123def456',
      'name' => 'Jane Doe',
      'email' => 'jane@example.com',
      'email_verified' => true
    }
  end

  before do
    allow(strategy).to receive(:raw_info).and_return(raw_info)
  end

  describe 'uid' do
    it 'returns the sub claim' do
      expect(strategy.uid).to eq('auth0|abc123def456')
    end
  end

  describe 'info' do
    it 'returns ChatGPT user info' do
      expect(strategy.info).to eq(
        {
          name: 'Jane Doe',
          email: 'jane@example.com',
          email_verified: true
        }
      )
    end
  end

  describe 'extra' do
    it 'returns raw_info' do
      expect(strategy.extra).to eq({ raw_info: raw_info })
    end
  end

  describe '#callback_url' do
    let(:base_url) { 'https://example.com' }

    context 'when script name is not present' do
      it 'has the correct default callback path' do
        allow(strategy).to receive(:full_host) { base_url }
        allow(strategy).to receive_messages(script_name: '', query_string: '')

        expect(strategy.callback_url).to eq("#{base_url}/users/auth/chatgpt/callback")
      end
    end

    context 'when script name is present' do
      it 'sets the callback path with script_name' do
        allow(strategy).to receive(:full_host) { base_url }
        allow(strategy).to receive_messages(script_name: '/v1', query_string: '')

        expect(strategy.callback_url).to eq("#{base_url}/v1/users/auth/chatgpt/callback")
      end
    end

    context 'when redirect_uri option is set' do
      it 'returns the redirect_uri' do
        strategy.options[:redirect_uri] = 'https://custom.example.com/callback'

        expect(strategy.callback_url).to eq('https://custom.example.com/callback')
      end
    end
  end

  describe 'client_options' do
    it 'uses correct URLs for API calls, authorization, and token exchange' do
      expect(strategy.options.client_options).to have_attributes(
        site: 'https://auth.openai.com',
        authorize_url: 'https://auth.openai.com/api/accounts/authorize',
        token_url: 'https://auth.openai.com/api/accounts/oauth/token'
      )
    end
  end

  describe 'authorize_params' do
    it 'requests openid, profile, and email scopes' do
      expect(strategy.options.authorize_params[:scope]).to eq('openid profile email')
    end
  end

  describe 'pkce' do
    it 'is enabled' do
      expect(strategy.options.pkce).to be true
    end
  end

  describe '#raw_info' do
    shared_examples 'failed ChatGPT JWKS fetch raises IdTokenError' do |status: nil|
      it 'logs the JWKS fetch error and raises IdTokenError' do
        jwks_error = { message: 'ChatGPT JWKS fetch failed' }
        jwks_error[:status] = status if status

        expect(Gitlab::AppLogger).to receive(:error)
          .with(hash_including(jwks_error)).ordered
        expect(Gitlab::AppLogger).to receive(:error)
          .with(hash_including(message: 'ChatGPT id_token decode failed')).ordered

        expect { strategy.raw_info }.to raise_error(described_class::IdTokenError)
      end
    end

    let(:rsa_key) { OpenSSL::PKey::RSA.generate(2048) }
    let(:jwk) { JWT::JWK.new(rsa_key, kid: 'test-kid') }
    let(:jwks) { JWT::JWK::Set.new(jwk) }
    let(:client_id) { 'test-client-id' }

    let(:id_token_claims) do
      raw_info.merge(
        'iss' => described_class::ISSUER,
        'aud' => client_id,
        'exp' => 1.hour.from_now.to_i,
        'iat' => Time.now.to_i
      )
    end

    let(:id_token) do
      JWT.encode(id_token_claims, rsa_key, 'RS256', { kid: 'test-kid' })
    end

    let(:access_token) { instance_double(OAuth2::AccessToken, params: { 'id_token' => id_token }) }

    before do
      allow(strategy).to receive(:raw_info).and_call_original
      allow(strategy).to receive(:access_token).and_return(access_token)
      allow(strategy).to receive_message_chain(:options, :client_id).and_return(client_id)
      allow(Rails.cache).to receive(:fetch)
        .with(described_class::JWKS_CACHE_KEY, expires_in: 1.hour, skip_nil: true)
        .and_return(jwks)
    end

    it 'decodes and verifies the id_token JWT payload', :aggregate_failures do
      result = strategy.raw_info

      expect(result['sub']).to eq('auth0|abc123def456')
      expect(result['name']).to eq('Jane Doe')
      expect(result['email']).to eq('jane@example.com')
      expect(result['email_verified']).to be true
    end

    context 'when id_token is nil' do
      let(:access_token) { instance_double(OAuth2::AccessToken, params: { 'id_token' => nil }) }

      it 'raises IdTokenError' do
        expect { strategy.raw_info }.to raise_error(described_class::IdTokenError, 'id_token is missing')
      end
    end

    context 'when id_token is absent' do
      let(:access_token) { instance_double(OAuth2::AccessToken, params: {}) }

      it 'raises IdTokenError' do
        expect { strategy.raw_info }.to raise_error(described_class::IdTokenError, 'id_token is missing')
      end
    end

    context 'when id_token has an invalid signature' do
      let(:other_key) { OpenSSL::PKey::RSA.generate(2048) }
      let(:id_token) { JWT.encode(id_token_claims, other_key, 'RS256', { kid: 'test-kid' }) }

      it 'raises IdTokenError' do
        expect { strategy.raw_info }.to raise_error(described_class::IdTokenError)
      end
    end

    context 'when id_token is malformed' do
      let(:access_token) { instance_double(OAuth2::AccessToken, params: { 'id_token' => 'not-a-jwt' }) }

      it 'raises IdTokenError' do
        expect { strategy.raw_info }.to raise_error(described_class::IdTokenError)
      end
    end

    context 'when JWKS endpoint returns a non-2xx response' do
      before do
        allow(Rails.cache).to receive(:fetch)
          .with(described_class::JWKS_CACHE_KEY, expires_in: 1.hour, skip_nil: true)
          .and_yield
        allow(Gitlab::HTTP).to receive(:get)
          .with(described_class::JWKS_URI, timeout: 5)
          .and_return(instance_double(HTTParty::Response, success?: false, code: 503))
      end

      it_behaves_like 'failed ChatGPT JWKS fetch raises IdTokenError', status: 503
    end

    context 'when an HTTP connection error occurs fetching JWKS' do
      before do
        allow(Rails.cache).to receive(:fetch)
          .with(described_class::JWKS_CACHE_KEY, expires_in: 1.hour, skip_nil: true)
          .and_yield
        allow(Gitlab::HTTP).to receive(:get).and_raise(Errno::ECONNREFUSED)
      end

      it_behaves_like 'failed ChatGPT JWKS fetch raises IdTokenError'
    end

    context 'when JWKS response has invalid format' do
      before do
        allow(Rails.cache).to receive(:fetch)
          .with(described_class::JWKS_CACHE_KEY, expires_in: 1.hour, skip_nil: true)
          .and_yield
        allow(Gitlab::HTTP).to receive(:get)
          .with(described_class::JWKS_URI, timeout: 5)
          .and_return(instance_double(HTTParty::Response, success?: true, parsed_response: 'not json'))
        allow(JWT::JWK::Set).to receive(:new).and_raise(JWT::JWKError, 'invalid format')
      end

      it_behaves_like 'failed ChatGPT JWKS fetch raises IdTokenError'
    end
  end
end
