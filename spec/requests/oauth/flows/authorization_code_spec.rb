# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Gitlab OAuth2 Authorization Code Flow', feature_category: :system_access do
  let_it_be(:application) { create(:oauth_application, redirect_uri: 'https://example.com/oauth/callback') }
  let_it_be(:user) { create(:user, :with_namespace, organizations: [create(:organization)]) }
  let_it_be(:client_id) { application.uid }
  let_it_be(:client_secret) { application.secret }

  let(:authorization_params) do
    {
      client_id: client_id,
      response_type: 'code',
      redirect_uri: application.redirect_uri,
      scope: 'api'
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

  def fetch_access_token(code)
    post oauth_token_path, params: token_params.merge(code: code)
    json_response['access_token']
  end

  describe 'Authorization Consent' do
    context 'with valid params' do
      it 'renders the authorization form' do
        get '/oauth/authorize', params: authorization_params

        expect(response).to have_gitlab_http_status(:ok)
        expect(response.body).to include('Authorize')
      end
    end

    context 'with invalid client_id' do
      it 'returns an error' do
        get '/oauth/authorize', params: { client_id: 'invalid', response_type: 'code' }

        expect(response.body).to include('failed due to unknown client')
        expect(response).to have_gitlab_http_status(:ok)
      end
    end

    context 'with invalid redirect_uri' do
      it 'returns an error' do
        get '/oauth/authorize', params: { client_id: client_id, response_type: 'code', redirect_uri: 'invalid' }

        expect(response.body).to include('The redirect URI included is not valid')
        expect(response).to have_gitlab_http_status(:ok)
      end
    end
  end

  describe 'Authorization Request' do
    context 'with valid params' do
      it 'redirects to authorization endpoint' do
        fetch_authorization_code

        expect(response).to have_gitlab_http_status(:found)
        expect(response.location).to start_with(application.redirect_uri)
      end
    end

    context 'with invalid client_id' do
      it 'returns an error' do
        post '/oauth/authorize', params: {
          client_id: 'invalid',
          response_type: 'code',
          redirect_uri: application.redirect_uri
        }

        expect(response.body).to include('failed due to unknown client')
        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end
  end

  describe 'Token Request' do
    context 'with valid authorization code' do
      it 'exchanges code for access token' do
        code = fetch_authorization_code
        fetch_access_token(code)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to include('access_token', 'token_type', 'expires_in', 'refresh_token')
      end
    end

    context 'with invalid authorization code' do
      it 'fails to exchange token' do
        fetch_access_token('invalid')

        expect(response).to have_gitlab_http_status(:bad_request)
      end
    end
  end

  describe 'Protected Resource Access' do
    let(:code) { fetch_authorization_code }
    let(:access_token) { fetch_access_token(code) }

    context 'with valid access token' do
      it 'grants access to protected resource' do
        get "/api/v4/user", headers: { Authorization: "Bearer #{access_token}" }

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['id']).to eq(user.id)
      end
    end

    context 'with invalid access token' do
      it 'denies access to protected resource' do
        get api_v4_user_path, headers: { Authorization: 'Bearer invalid_token' }

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end
  end
end
