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

  def fetch_token_response(code)
    post oauth_token_path, params: token_params.merge(code: code)
    json_response
  end

  def refresh_access_token(refresh_token)
    post oauth_token_path, params: {
      client_id: client_id,
      client_secret: client_secret,
      grant_type: 'refresh_token',
      refresh_token: refresh_token
    }
    json_response
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

    context 'with reused authorization code' do
      it 'fails on second attempt to exchange same code' do
        code = fetch_authorization_code

        # First exchange should succeed
        fetch_access_token(code)
        expect(response).to have_gitlab_http_status(:ok)

        # Second exchange with same code should fail
        fetch_access_token(code)
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

  describe 'Refresh Token Flow' do
    let(:code) { fetch_authorization_code }
    let(:initial_token_response) { fetch_token_response(code) }
    let(:initial_access_token) { initial_token_response['access_token'] }
    let(:initial_refresh_token) { initial_token_response['refresh_token'] }

    context 'with valid refresh token' do
      it 'exchanges refresh token for new access token' do
        initial_token_response

        refreshed_response = refresh_access_token(initial_refresh_token)

        expect(response).to have_gitlab_http_status(:ok)
        expect(refreshed_response).to include('access_token', 'token_type', 'expires_in', 'refresh_token')
        expect(refreshed_response['access_token']).not_to eq(initial_access_token)
      end

      it 'allows access to protected resources with refreshed token' do
        initial_token_response

        refreshed_response = refresh_access_token(initial_refresh_token)
        new_access_token = refreshed_response['access_token']

        get "/api/v4/user", headers: { Authorization: "Bearer #{new_access_token}" }

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['id']).to eq(user.id)
      end

      it 'maintains same scope after refresh' do
        initial_token_response

        refreshed_response = refresh_access_token(initial_refresh_token)

        expect(refreshed_response['scope']).to eq('api')
      end
    end

    context 'with invalid refresh token' do
      it 'fails to refresh with invalid token' do
        refresh_access_token('invalid_refresh_token')

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response['error']).to be_present
      end
    end

    context 'with expired or revoked refresh token' do
      it 'invalidates old refresh token after use' do
        initial_token_response

        # Use refresh token once
        refresh_access_token(initial_refresh_token)
        expect(response).to have_gitlab_http_status(:ok)

        # Try to use the same initial refresh token again
        refresh_access_token(initial_refresh_token)
        expect(response).to have_gitlab_http_status(:bad_request)
      end

      it 'handles revoked application refresh tokens' do
        initial_token_response

        # Revoke application's tokens
        application.access_tokens.update_all(revoked_at: Time.current)

        refresh_access_token(initial_refresh_token)

        expect(response).to have_gitlab_http_status(:bad_request)
      end
    end
  end

  describe 'Complete OAuth Flow with Refresh with legacy hashing' do
    before do
      stub_feature_flags(sha512_oauth: false)
    end

    it 'completes full authorization, access, refresh, and re-access cycle' do
      # Step 1: Get authorization code
      code = fetch_authorization_code
      expect(code).to be_present

      # Step 2: Exchange code for tokens
      initial_response = fetch_token_response(code)
      initial_access = initial_response['access_token']
      initial_refresh = initial_response['refresh_token']

      expect(initial_access).to be_present
      expect(initial_refresh).to be_present

      # Step 3: Use initial access token
      get "/api/v4/user", headers: { Authorization: "Bearer #{initial_access}" }
      expect(response).to have_gitlab_http_status(:ok)
      initial_user_data = json_response

      # Step 4: Turn on FF and refresh tokens
      stub_feature_flags(sha512_oauth: true)
      refreshed_response = refresh_access_token(initial_refresh)
      new_access = refreshed_response['access_token']
      new_refresh = refreshed_response['refresh_token']

      expect(new_access).not_to eq(initial_access)
      expect(new_refresh).not_to eq(initial_refresh)

      # Step 5: Use new access token
      get "/api/v4/user", headers: { Authorization: "Bearer #{new_access}" }
      expect(response).to have_gitlab_http_status(:ok)
      new_user_data = json_response

      # Step 6: Verify same user data
      expect(new_user_data['id']).to eq(initial_user_data['id'])
      expect(new_user_data['id']).to eq(user.id)
    end
  end
end
