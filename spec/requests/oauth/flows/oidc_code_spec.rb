# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Gitlab OIDC Authorization Code Flow', feature_category: :system_access do
  let_it_be(:application) { create(:oauth_application, redirect_uri: 'https://example.com/oauth/callback', scopes: 'openid profile email api') }
  let_it_be(:user) { create(:user, :with_namespace, email: 'test@example.com', organizations: [create(:organization)]) }
  let_it_be(:client_id) { application.uid }
  let_it_be(:client_secret) { application.secret }

  let(:authorization_params) do
    {
      client_id: client_id,
      response_type: 'code',
      redirect_uri: application.redirect_uri,
      scope: 'openid profile email api',
      nonce: 'nonce'
    }
  end

  let(:token_params) do
    {
      client_id: client_id,
      client_secret: client_secret,
      grant_type: 'authorization_code',
      redirect_uri: application.redirect_uri
    }
  end

  before do
    sign_in(user)
  end

  def fetch_authorization_code
    post '/oauth/authorize', params: authorization_params
    Addressable::URI.parse(response.location).query_values['code']
  end

  def fetch_tokens(code)
    post oauth_token_path, params: token_params.merge(code: code)
    json_response
  end

  describe 'OIDC Authorization Request' do
    context 'with valid params' do
      it 'redirects to the authorization endpoint' do
        post '/oauth/authorize', params: authorization_params

        expect(response).to have_gitlab_http_status(:found)
        expect(response.location).to start_with(application.redirect_uri)
      end

      it 'redirects to the authorization endpoint even if the nonce is missing' do
        post '/oauth/authorize', params: authorization_params.except(:nonce)

        expect(response).to have_gitlab_http_status(:found)
        expect(response.location).to start_with(application.redirect_uri)
      end
    end

    context 'with invalid client_id' do
      it 'returns an error' do
        post '/oauth/authorize', params: authorization_params.merge(client_id: 'invalid')

        expect(response).to have_gitlab_http_status(:unauthorized)
        expect(response.body).to include('Client authentication failed')
      end
    end
  end

  describe 'OIDC Token Request' do
    let(:code) { fetch_authorization_code }

    context 'with valid authorization code' do
      it 'returns access token and ID token' do
        tokens = fetch_tokens(code)

        expect(response).to have_gitlab_http_status(:ok)
        expect(tokens).to include('access_token', 'id_token', 'expires_in')
      end

      it 'validates ID token structure' do
        tokens = fetch_tokens(code)
        id_token = tokens['id_token']
        decoded_token = JWT.decode(id_token, nil, false).first

        expect(decoded_token).to include(
          'iss' => "http://localhost",
          'aud' => client_id,
          'sub' => user.id.to_s,
          'email' => user.email
        )
        expect(decoded_token['exp']).to be > Time.now.to_i
      end
    end

    context 'with invalid authorization code' do
      it 'returns an error' do
        post oauth_token_path, params: token_params.merge(code: 'invalid_code')

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response['error']).to eq('invalid_grant')
      end
    end

    context 'with missing client_secret for confidential client' do
      it 'returns an error' do
        post oauth_token_path, params: token_params.except(:client_secret).merge(code: code)

        expect(response).to have_gitlab_http_status(:unauthorized)
        expect(json_response['error']).to eq('invalid_client')
      end
    end
  end

  describe 'Protected Resource Access' do
    let(:tokens) { fetch_tokens(fetch_authorization_code) }
    let(:access_token) { tokens['access_token'] }

    context 'with valid access token' do
      it 'allows access to protected resource' do
        get '/api/v4/user', headers: { Authorization: "Bearer #{access_token}" }

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['id']).to eq(user.id)
        expect(json_response['email']).to eq(user.email)
      end
    end

    context 'with invalid access token' do
      it 'denies access to protected resource' do
        get '/api/v4/user', headers: { Authorization: 'Bearer invalid_token' }

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end
  end
end
