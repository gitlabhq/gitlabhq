# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Gitlab OAuth2 Device Authorization Grant', feature_category: :system_access do
  let_it_be(:organization) { create(:organization, :default) }
  let_it_be(:application) { create(:oauth_application, redirect_uri: 'urn:ietf:wg:oauth:2.0:oob', confidential: false) }
  let_it_be(:user) { create(:user, :with_namespace, organizations: [organization]) }
  let_it_be(:client_id) { application.uid }
  let_it_be(:client_secret) { application.secret }

  let(:device_authorization_params) do
    {
      client_id: client_id,
      scope: 'api'
    }
  end

  let(:token_params) do
    {
      client_id: client_id,
      grant_type: 'urn:ietf:params:oauth:grant-type:device_code'
    }
  end

  before do
    sign_in(user)
  end

  def fetch_device_code
    post '/oauth/authorize_device',
      params: device_authorization_params,
      headers: { 'Content-Type' => 'application/x-www-form-urlencoded' }
    json_response
  end

  def fetch_access_token(device_code)
    post oauth_token_path, params: token_params.merge(device_code: device_code)
    json_response
  end

  def verify_device_code(device_code_response)
    user_code = device_code_response['user_code']
    verification_uri = device_code_response['verification_uri']

    post verification_uri, params: { user_code: user_code }
  end

  describe 'Device Authorization Request' do
    context 'with valid client_id' do
      it 'returns device code and verification URI' do
        response_body = fetch_device_code

        expect(response).to have_gitlab_http_status(:ok)
        expect(response_body).to include('device_code', 'user_code', 'verification_uri', 'expires_in')
      end
    end

    context 'with invalid client_id' do
      it 'returns an error' do
        post '/oauth/authorize_device', params: device_authorization_params.merge(client_id: 'invalid')

        expect(response).to have_gitlab_http_status(:unauthorized)
        expect(json_response['error']).to eq('invalid_client')
      end
    end
  end

  describe 'Token Request with Device Code' do
    let(:device_code_response) { fetch_device_code }
    let(:device_code) { device_code_response['device_code'] }

    context 'with valid device code' do
      it 'returns access token' do
        verify_device_code(device_code_response)
        token_response = fetch_access_token(device_code)

        expect(response).to have_gitlab_http_status(:ok)
        expect(token_response).to include('access_token', 'token_type', 'expires_in', 'refresh_token')
      end
    end

    context 'with invalid device code' do
      it 'returns an error' do
        fetch_access_token('invalid_code')

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response['error']).to eq('invalid_grant')
      end
    end

    context 'with pending device code verification' do
      it 'returns authorization pending error' do
        fetch_access_token(device_code)

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response['error']).to eq('authorization_pending')
      end
    end

    context 'with expired device code' do
      it 'returns expired device code error' do
        verify_device_code(device_code_response)
        travel_to 1.hour.from_now do
          fetch_access_token(device_code)
        end

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response['error']).to eq('expired_token')
      end
    end
  end

  describe 'User Verification Flow' do
    let(:device_code_response) { fetch_device_code }
    let(:user_code) { device_code_response['user_code'] }
    let(:verification_uri) { device_code_response['verification_uri'] }

    it 'allows user to verify the device code' do
      post verification_uri, params: { user_code: user_code }
      follow_redirect!

      expect(response).to have_gitlab_http_status(:ok)
      expect(response.body).to include('Device successfully authorized')
    end

    it 'fails with an invalid user code' do
      post verification_uri, params: { user_code: 'invalid' }
      follow_redirect!

      expect(response).to have_gitlab_http_status(:ok)
      expect(response.body).to include('The user code is invalid')
    end
  end
end
