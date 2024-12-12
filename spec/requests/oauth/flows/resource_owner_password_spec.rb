# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Gitlab OAuth2 Resource Owner Password Credentials Flow', feature_category: :system_access do
  let_it_be(:organization) { create(:organization, :default) }
  let_it_be(:application) { create(:oauth_application, redirect_uri: 'urn:ietf:wg:oauth:2.0:oob') }
  let_it_be(:user) { create(:user, :with_namespace, organizations: [organization], password: 'High5ive!') }
  let_it_be(:client_id) { application.uid }
  let_it_be(:client_secret) { application.secret }

  let(:token_params) do
    {
      client_id: client_id,
      client_secret: client_secret,
      grant_type: 'password',
      username: user.username,
      password: user.password,
      scope: 'api'
    }
  end

  def fetch_access_token(params)
    post oauth_token_path, params: params
    json_response
  end

  describe 'Token Request with Resource Owner Password' do
    context 'with valid credentials' do
      it 'returns an access token' do
        token_response = fetch_access_token(token_params)

        expect(response).to have_gitlab_http_status(:ok)
        expect(token_response).to include('access_token', 'token_type', 'expires_in', 'refresh_token')
      end
    end

    context 'without client_id and client_secret' do
      it 'returns an access token' do
        token_response = fetch_access_token(token_params.except(:client_id, :client_secret))

        expect(response).to have_gitlab_http_status(:ok)
        expect(token_response).to include('access_token', 'token_type', 'expires_in', 'refresh_token')
      end
    end

    context 'with invalid username' do
      it 'returns an error' do
        token_response = fetch_access_token(token_params.merge(username: 'invalid_user'))

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(token_response['error']).to eq('invalid_grant')
      end
    end

    context 'with invalid password' do
      it 'returns an error' do
        token_response = fetch_access_token(token_params.merge(password: 'wrong_password'))

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(token_response['error']).to eq('invalid_grant')
      end
    end

    context 'with missing credentials' do
      it 'returns an error' do
        token_response = fetch_access_token(token_params.except(:username, :password))

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(token_response['error']).to eq('invalid_grant')
      end
    end

    context 'with invalid client_id' do
      it 'returns an error' do
        token_response = fetch_access_token(token_params.merge(client_id: 'invalid_client'))

        expect(response).to have_gitlab_http_status(:unauthorized)
        expect(token_response['error']).to eq('invalid_client')
      end
    end

    context 'with missing client_secret for confidential client' do
      it 'returns an error' do
        token_response = fetch_access_token(token_params.except(:client_secret))

        expect(response).to have_gitlab_http_status(:unauthorized)
        expect(token_response['error']).to eq('invalid_client')
      end
    end
  end

  describe 'Protected Resource Access with ROPC' do
    let(:access_token) { fetch_access_token(token_params)['access_token'] }

    context 'with valid access token' do
      it 'allows access to protected resource' do
        get '/api/v4/user', headers: { Authorization: "Bearer #{access_token}" }

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['id']).to eq(user.id)
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
