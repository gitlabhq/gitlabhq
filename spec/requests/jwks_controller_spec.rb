# frozen_string_literal: true

require 'spec_helper'

RSpec.describe JwksController, feature_category: :system_access do
  describe 'Endpoints from the parent Doorkeeper::OpenidConnect::DiscoveryController' do
    it 'respond successfully' do
      [
        "/oauth/discovery/keys",
        "/.well-known/openid-configuration",
        "/.well-known/oauth-authorization-server",
        "/.well-known/oauth-authorization-server/api/v4/mcp",
        "/.well-known/openid-configuration/api/v4/mcp",
        "/.well-known/webfinger?resource=#{create(:user).email}"
      ].each do |endpoint|
        get endpoint
        expect(response).to have_gitlab_http_status(:ok)
      end
    end
  end

  describe '/.well-known/openid-configuration' do
    let(:parsed_response) { Gitlab::Json.parse(response.body) }
    let(:oauth_endpoints) do
      %w[authorization_endpoint token_endpoint revocation_endpoint introspection_endpoint userinfo_endpoint]
    end

    before do
      allow(Gitlab.config.gitlab).to receive(:protocol).and_return(protocol)
      get "/.well-known/openid-configuration"
    end

    context 'when protocol is https' do
      let(:protocol) { 'https' }

      it 'returns OAuth endpoints with https protocol' do
        oauth_endpoints.each do |endpoint|
          expect(parsed_response[endpoint]).to start_with('https://')
        end
      end
    end

    context 'when protocol is http' do
      let(:protocol) { 'http' }

      it 'returns OAuth endpoints with http protocol' do
        oauth_endpoints.each do |endpoint|
          expect(parsed_response[endpoint]).to start_with('http://')
        end
      end
    end

    describe 'additional claims support' do
      let(:protocol) { 'https' }
      let(:additional_claims) { %w[project_path ci_config_ref_uri ref_path sha environment jti] }

      before do
        get "/.well-known/openid-configuration"
      end

      it 'includes additional claims in claims_supported' do
        additional_claims.each do |claim|
          expect(parsed_response['claims_supported']).to include(claim)
        end
      end
    end
  end

  describe '/oauth/discovery/keys' do
    include_context 'when doing OIDC key discovery'

    it 'removes missing keys' do
      expect(Rails.application.credentials).to receive(:openid_connect_signing_key).and_return(rsa_key_1.to_pem)
      expect(Gitlab::CurrentSettings).to receive(:ci_jwt_signing_key).and_return(nil)

      expect(jwks.size).to eq(1)
      expect(jwks).to match_array([
        satisfy { |jwk| key_match?(jwk, rsa_key_1) }
      ])
    end

    it 'removes duplicate keys' do
      expect(Rails.application.credentials).to receive(:openid_connect_signing_key).and_return(rsa_key_1.to_pem)
      expect(Gitlab::CurrentSettings).to receive(:ci_jwt_signing_key).and_return(rsa_key_1.to_pem)

      expect(jwks.size).to eq(1)
      expect(jwks).to match_array([
        satisfy { |jwk| key_match?(jwk, rsa_key_1) }
      ])
    end
  end

  describe 'MCP-specific OAuth discovery endpoint' do
    let(:parsed_response) { Gitlab::Json.parse(response.body) }

    context 'when accessing MCP-specific discovery endpoint' do
      before do
        get '/.well-known/oauth-authorization-server/api/v4/mcp'
      end

      it 'returns only mcp scope in scopes_supported' do
        expect(response).to have_gitlab_http_status(:ok)
        expect(parsed_response['scopes_supported']).to eq(['mcp'])
      end

      it 'includes registration_endpoint' do
        expect(parsed_response['registration_endpoint']).to end_with('/oauth/register')
      end
    end

    context 'when accessing general OAuth discovery endpoint' do
      before do
        get '/.well-known/oauth-authorization-server'
      end

      it 'returns all available scopes in scopes_supported', :aggregate_failures do
        expect(response).to have_gitlab_http_status(:ok)
        expect(parsed_response['scopes_supported']).to include('api', 'read_api', 'mcp')
        expect(parsed_response['scopes_supported'].size).to be > 1
      end

      it 'includes registration_endpoint' do
        expect(parsed_response['registration_endpoint']).to end_with('/oauth/register')
      end
    end
  end
end
