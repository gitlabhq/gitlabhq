# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Gitlab OAuth2 Client Credentials Flow', feature_category: :system_access do
  let_it_be(:organization) { create(:organization) }
  let_it_be(:application) { create(:oauth_application, scopes: 'api read_user') }
  let_it_be(:client_id) { application.uid }
  let_it_be(:client_secret) { application.secret }
  let(:token_params) do
    {
      client_id: client_id,
      client_secret: client_secret,
      grant_type: 'client_credentials',
      scope: 'api'
    }
  end

  before do
    allow_next_instance_of(Gitlab::Current::Organization) do |instance|
      allow(instance).to receive(:organization).and_return(organization)
    end
  end

  def fetch_access_token(params = token_params)
    post oauth_token_path, params: params
    json_response
  end

  describe 'Token Request' do
    context 'with valid client credentials' do
      it 'returns an access token' do
        fetch_access_token

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to include('access_token', 'token_type', 'expires_in', 'scope')
      end

      it 'returns a bearer token type' do
        fetch_access_token

        expect(json_response['token_type']).to eq('Bearer')
      end

      it 'does not return a refresh token' do
        fetch_access_token

        expect(json_response).not_to include('refresh_token')
      end

      it 'returns the requested scope' do
        fetch_access_token

        expect(json_response['scope']).to eq('api')
      end
    end

    context 'with invalid client_id' do
      it 'returns an error' do
        fetch_access_token(token_params.merge(client_id: 'invalid'))

        expect(response).to have_gitlab_http_status(:unauthorized)
        expect(json_response['error']).to eq('invalid_client')
      end
    end

    context 'with invalid client_secret' do
      it 'returns an error' do
        fetch_access_token(token_params.merge(client_secret: 'invalid'))

        expect(response).to have_gitlab_http_status(:unauthorized)
        expect(json_response['error']).to eq('invalid_client')
      end
    end

    context 'with missing client_secret' do
      it 'returns an error' do
        fetch_access_token(token_params.except(:client_secret))

        expect(response).to have_gitlab_http_status(:unauthorized)
        expect(json_response['error']).to eq('invalid_client')
      end
    end

    context 'with a scope beyond application limits' do
      it 'returns an invalid_scope error' do
        fetch_access_token(token_params.merge(scope: 'sudo'))

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response['error']).to eq('invalid_scope')
      end
    end

    context 'with no scope specified' do
      it 'returns an access token using the application default scopes' do
        fetch_access_token(token_params.except(:scope))

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to include('access_token')
      end
    end

    context 'with client credentials via HTTP Basic Auth' do
      it 'returns an access token' do
        post oauth_token_path,
          params: { grant_type: 'client_credentials', scope: 'api' },
          headers: { 'Authorization' => ActionController::HttpAuthentication::Basic.encode_credentials(client_id, client_secret) }

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to include('access_token')
      end
    end
  end
end
