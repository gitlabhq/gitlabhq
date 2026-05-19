# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'OAuth tokens', feature_category: :system_access do
  include HttpBasicAuthHelpers

  let_it_be(:organization) { create(:organization) }

  before do
    allow_next_instance_of(Gitlab::Current::Organization) do |instance|
      allow(instance).to receive(:organization).and_return(organization)
    end
  end

  context 'Device Grant flow' do
    let_it_be(:client) { create(:oauth_application, :with_device_code_enabled, confidential: false) }
    let_it_be(:user) { create(:user) }

    def request_device_token(app_id, headers = {})
      post '/oauth/authorize_device',
        params: { client_id: app_id, scope: "api" },
        headers: headers
    end

    context 'when device_code_enabled is false' do
      before do
        client.update!(device_code_enabled: false)
      end

      it 'fails' do
        request_device_token(client.uid)

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response['error']).to eq('access_denied')
      end
    end

    context 'when generating a device code' do
      context 'with an invalid client id' do
        it 'fails' do
          request_device_token('invalid')

          expect(response).to have_gitlab_http_status(:unauthorized)
          expect(json_response['error']).to eq('invalid_client')
        end
      end

      context 'with a valid client id' do
        it 'creates a device token' do
          request_device_token(client.uid)

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['device_code']).not_to be_nil
          expect(json_response['verification_uri']).not_to be_nil
          expect(json_response['verification_uri_complete']).not_to be_nil
        end
      end
    end

    context 'when generating an access token' do
      def request_access_token(app_id, device_code)
        post '/oauth/token',
          params: {
            client_id: app_id,
            device_code: device_code,
            grant_type: 'urn:ietf:params:oauth:grant-type:device_code'
          }
      end

      context 'with an invalid client id' do
        it 'fails' do
          request_device_token(client.uid)

          device_code = json_response['device_code']

          request_access_token('invalid', device_code)

          expect(response).to have_gitlab_http_status(:unauthorized)
          expect(json_response['error']).to eq('invalid_client')
        end
      end

      context 'with an invalid device code' do
        it 'fails' do
          request_access_token(client.uid, 'invalid')

          expect(response).to have_gitlab_http_status(:bad_request)
          expect(json_response['error']).to eq('invalid_grant')
        end
      end

      context 'when authorization is pending' do
        it 'fails' do
          request_device_token(client.uid)

          device_code = json_response['device_code']

          request_access_token(client.uid, device_code)

          expect(response).to have_gitlab_http_status(:bad_request)
          expect(json_response['error']).to eq('authorization_pending')
        end
      end

      context 'with a valid device code' do
        it 'creates an access token' do
          request_device_token(client.uid)

          device_code = json_response['device_code']
          user_code = json_response['user_code']

          model = Doorkeeper::DeviceAuthorizationGrant.configuration.device_grant_model
          device_grant = model.lock.find_by(user_code: user_code)
          device_grant.update!(user_code: nil, resource_owner_id: user.id)

          request_access_token(client.uid, device_code)

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['access_token']).not_to be_nil
        end
      end
    end
  end
end
