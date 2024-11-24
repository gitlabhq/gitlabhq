# frozen_string_literal: true

require 'rails_helper'

describe Doorkeeper::OpenidConnect::DiscoveryController, type: :controller do
  describe '#provider' do
    it 'returns the provider configuration' do
      get :provider
      data = JSON.parse(response.body)

      expect(data.sort).to match({
        'issuer' => 'dummy',
        'authorization_endpoint' => 'http://test.host/oauth/authorize',
        'token_endpoint' => 'http://test.host/oauth/token',
        'revocation_endpoint' => 'http://test.host/oauth/revoke',
        'introspection_endpoint' => 'http://test.host/oauth/introspect',
        'userinfo_endpoint' => 'http://test.host/oauth/userinfo',
        'jwks_uri' => 'http://test.host/oauth/discovery/keys',

        'scopes_supported' => ['openid'],
        'response_types_supported' => ['code', 'token', 'id_token', 'id_token token'],
        'response_modes_supported' => %w[query fragment form_post],
        'grant_types_supported' => %w[authorization_code client_credentials implicit_oidc],

        'token_endpoint_auth_methods_supported' => %w[client_secret_basic client_secret_post],

        'subject_types_supported' => [
          'public',
        ],

        'id_token_signing_alg_values_supported' => [
          'RS256',
        ],

        'claim_types_supported' => [
          'normal',
        ],

        'claims_supported' => %w[
          iss
          sub
          aud
          exp
          iat
          name
          variable_name
          created_at
          updated_at
          token_id
          both_responses
          id_token_response
          user_info_response
        ],

        'code_challenge_methods_supported' => %w[
          plain
          S256
        ],
      }.sort)
    end

    context 'when refresh_token grant type is enabled' do
      before { Doorkeeper.configure { use_refresh_token } }

      it 'add refresh_token to grant_types_supported' do
        get :provider
        data = JSON.parse(response.body)

        expect(data['grant_types_supported']).to eq %w[authorization_code client_credentials refresh_token]
      end
    end

    context 'when issuer block' do
      before { Doorkeeper::OpenidConnect.configure { issuer do |r, a| "test-issuer" end } }

      it 'return blocks result' do
        get :provider
        data = JSON.parse(response.body)

        expect(data['issuer']).to eq "test-issuer"
      end
    end

    context 'when grant_flows is configed with only client_credentials' do
      before { Doorkeeper.configure { grant_flows %w[client_credentials] } }

      it 'return empty response_modes_supported' do
        get :provider
        data = JSON.parse(response.body)

        expect(data['response_modes_supported']).to eq []
      end
    end

    context 'when grant_flows is configed only implicit flow' do
      before { Doorkeeper.configure { grant_flows %w[implicit_oidc] } }

      it 'return fragment and form_post as response_modes_supported' do
        get :provider
        data = JSON.parse(response.body)

        expect(data['response_modes_supported']).to eq %w[fragment form_post]
      end
    end

    context 'when grant_flows is configed with authorization_code and implicit flow' do
      before { Doorkeeper.configure { grant_flows %w[authorization_code implicit_oidc] } }

      it 'return query, fragment and form_post as response_modes_supported' do
        get :provider
        data = JSON.parse(response.body)

        expect(data['response_modes_supported']).to eq %w[query fragment form_post]
      end
    end

    it 'uses the protocol option for generating URLs' do
      Doorkeeper::OpenidConnect.configure do
        protocol { :testing }
      end

      get :provider
      data = JSON.parse(response.body)

      expect(data['authorization_endpoint']).to eq 'testing://test.host/oauth/authorize'
    end

    context 'when the discovery_url_options option is set for all endpoints' do
      before do
        Doorkeeper::OpenidConnect.configure do
          discovery_url_options do |request|
            {
              authorization: { host: 'alternate-authorization.host' },
              token: { host: 'alternate-token.host' },
              revocation: { host: 'alternate-revocation.host' },
              introspection: { host: 'alternate-introspection.host' },
              userinfo: { host: 'alternate-userinfo.host' },
              jwks: { host: 'alternate-jwks.host' }
            }
          end
        end
      end

      it 'uses the discovery_url_options option when generating the endpoint urls' do
        get :provider
        data = JSON.parse(response.body)

        expect(data['authorization_endpoint']).to eq 'http://alternate-authorization.host/oauth/authorize'
        expect(data['token_endpoint']).to eq 'http://alternate-token.host/oauth/token'
        expect(data['revocation_endpoint']).to eq 'http://alternate-revocation.host/oauth/revoke'
        expect(data['introspection_endpoint']).to eq 'http://alternate-introspection.host/oauth/introspect'
        expect(data['userinfo_endpoint']).to eq 'http://alternate-userinfo.host/oauth/userinfo'
        expect(data['jwks_uri']).to eq 'http://alternate-jwks.host/oauth/discovery/keys'
      end
    end

    context 'when the discovery_url_options option is only set for some endpoints' do
      before do
        Doorkeeper::OpenidConnect.configure do
          discovery_url_options do |request|
            { authorization: { host: 'alternate-authorization.host' } }
          end
        end
      end

      it 'does not use the discovery_url_options option when generating other URLs' do
        get :provider
        data = JSON.parse(response.body)

        {
          'token_endpoint' => 'http://test.host/oauth/token',
          'revocation_endpoint' => 'http://test.host/oauth/revoke',
          'introspection_endpoint' => 'http://test.host/oauth/introspect',
          'userinfo_endpoint' => 'http://test.host/oauth/userinfo',
          'jwks_uri' => 'http://test.host/oauth/discovery/keys',
        }.each do |endpoint, expected_url|
          expect(data[endpoint]).to eq expected_url
        end
      end
    end

    it 'does not return an end session endpoint if none is configured' do
      get :provider
      data = JSON.parse(response.body)

      expect(data.key?('end_session_endpoint')).to be(false)
    end

    it 'uses the configured end session endpoint with self as context' do
      Doorkeeper::OpenidConnect.configure do
        end_session_endpoint -> { logout_url }
      end

      def controller.logout_url
        'http://test.host/logout'
      end

      get :provider
      data = JSON.parse(response.body)

      expect(data['end_session_endpoint']).to eq 'http://test.host/logout'
    end

    context 'when token inspection is disallowed' do
      let(:doorkeeper_config) { Doorkeeper.config }
      let!(:allow_token_introspection) { doorkeeper_config.allow_token_introspection }

      before do
        allow(doorkeeper_config).to receive(:allow_token_introspection).and_return(false)
        Rails.application.reload_routes!
      end

      after do
        allow(doorkeeper_config).to receive(:allow_token_introspection).and_return(allow_token_introspection)
        Rails.application.reload_routes!
      end

      it 'does not return introspection_endpoint' do
        get :provider
        data = JSON.parse(response.body)

        expect(data.key?('introspection_endpoint')).to be(false)
      end
    end
  end

  describe '#webfinger' do
    it 'requires the resource parameter' do
      expect do
        get :webfinger
      end.to raise_error ActionController::ParameterMissing
    end

    it 'returns the OpenID Connect relation' do
      get :webfinger, params: { resource: 'user@example.com' }
      data = JSON.parse(response.body)

      expect(data.sort).to eq({
        'subject' => 'user@example.com',
        'links' => [
          'rel' => 'http://openid.net/specs/connect/1.0/issuer',
          'href' => 'http://test.host/',
        ],
      }.sort)
    end

    context 'when the discovery_url_options option is set for webfinger endpoint' do
      before do
        Doorkeeper::OpenidConnect.configure do
          discovery_url_options do |request|
            { webfinger: { host: 'alternate-webfinger.host' } }
          end
        end
      end

      it 'uses the discovery_url_options option when generating the webfinger endpoint url' do
        get :webfinger, params: { resource: 'user@example.com' }
        data = JSON.parse(response.body)

        expect(data['links'].first['href']).to eq 'http://alternate-webfinger.host/'
      end
    end

    context 'when the discovery_url_options option uses the request for an endpoint' do
      before do
        Doorkeeper::OpenidConnect.configure do
          discovery_url_options do |request|
            {
              authorization: { host: 'alternate-authorization.host',
                               protocol: request.ssl? ? :https : :testing }
            }
          end
        end
      end

      it 'uses the discovery_url_options option when generating the webfinger endpoint url' do
        get :provider
        data = JSON.parse(response.body)

        expect(data['authorization_endpoint']).to eq 'testing://alternate-authorization.host/oauth/authorize'
      end
    end
  end

  describe '#keys' do
    subject { get :keys }

    shared_examples 'a key response' do |options|
      expected_parameters = options[:expected_parameters]

      it "includes only #{expected_parameters.join(', ')} parameters" do
        subject
        data = JSON.parse(response.body)
        key = data['keys'].first

        expect(key.keys.map(&:to_sym)).to match_array(expected_parameters)
      end
    end

    context 'when using an RSA key' do
      it_behaves_like 'a key response', expected_parameters: %i[kty kid e n use alg]
    end

    context 'when using an EC key' do
      before { configure_ec }

      it_behaves_like 'a key response', expected_parameters: %i[kty kid crv x y use alg]
    end

    context 'when using an HMAC key' do
      before { configure_hmac }

      it_behaves_like 'a key response', expected_parameters: %i[kty kid use alg]
    end
  end
end
