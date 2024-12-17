# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Gitlab OAuth2 Authorization Code Flow with PKCE', feature_category: :system_access do
  let_it_be(:application) { create(:oauth_application, redirect_uri: 'https://example.com/oauth/callback', confidential: false) }
  let_it_be(:user) { create(:user, :with_namespace, organizations: [create(:organization)]) }
  let_it_be(:client_id) { application.uid }
  let_it_be(:client_secret) { application.secret }

  let(:code_verifier) { SecureRandom.urlsafe_base64(64) }
  let(:code_challenge) { Base64.urlsafe_encode64(Digest::SHA256.digest(code_verifier), padding: false) }
  let(:code_challenge_method) { 'S256' }

  let(:authorization_params) do
    {
      client_id: client_id,
      response_type: 'code',
      redirect_uri: application.redirect_uri,
      scope: 'api',
      code_challenge: code_challenge,
      code_challenge_method: code_challenge_method,
      state: 'abcd'
    }
  end

  let(:token_params) do
    {
      client_id: client_id,
      grant_type: 'authorization_code',
      redirect_uri: application.redirect_uri,
      code_verifier: code_verifier
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
    post '/oauth/token', params: token_params.merge(code: code)
    json_response['access_token']
  end

  describe 'Authorization Consent with PKCE' do
    context 'with valid PKCE params' do
      it 'renders the authorization form' do
        get '/oauth/authorize', params: authorization_params

        expect(response).to have_gitlab_http_status(:ok)
        expect(response.body).to include('Authorize')
      end
    end
  end

  describe 'Authorization Request with PKCE' do
    context 'with valid PKCE params' do
      it 'redirects to authorization endpoint' do
        fetch_authorization_code

        expect(response).to have_gitlab_http_status(:found)
        expect(response.location).to start_with(application.redirect_uri)
      end
    end
  end

  describe 'Token Request with PKCE' do
    context 'with valid authorization code and code_verifier' do
      it 'exchanges code for access token' do
        code = fetch_authorization_code
        fetch_access_token(code)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to include('access_token', 'token_type', 'expires_in', 'refresh_token')
      end
    end

    context 'with invalid code_verifier' do
      it 'fails to exchange token' do
        code = fetch_authorization_code
        post oauth_token_path, params: token_params.merge(code: code, code_verifier: 'invalid')

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response['error']).to eq('invalid_grant')
      end
    end
  end

  describe 'Protected Resource Access with PKCE' do
    let(:code) { fetch_authorization_code }
    let(:access_token) { fetch_access_token(code) }

    context 'with valid access token' do
      it 'grants access to protected resource' do
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
