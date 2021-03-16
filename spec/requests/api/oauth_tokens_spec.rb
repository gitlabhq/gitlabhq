# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'OAuth tokens' do
  include HttpBasicAuthHelpers

  context 'Resource Owner Password Credentials' do
    def request_oauth_token(user, headers = {})
      post '/oauth/token',
         params: { username: user.username, password: user.password, grant_type: 'password' },
         headers: headers
    end

    let_it_be(:client) { create(:oauth_application) }

    context 'when user has 2FA enabled' do
      it 'does not create an access token' do
        user = create(:user, :two_factor)

        request_oauth_token(user, client_basic_auth_header(client))

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response['error']).to eq('invalid_grant')
      end
    end

    context 'when user does not have 2FA enabled' do
      context 'when no client credentials provided' do
        it 'creates an access token' do
          user = create(:user)

          request_oauth_token(user)

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['access_token']).to be_present
        end
      end

      context 'when client credentials provided' do
        context 'with valid credentials' do
          it 'creates an access token' do
            user = create(:user)

            request_oauth_token(user, client_basic_auth_header(client))

            expect(response).to have_gitlab_http_status(:ok)
            expect(json_response['access_token']).not_to be_nil
          end
        end

        context 'with invalid credentials' do
          it 'does not create an access token' do
            pending 'Enable this example after https://github.com/doorkeeper-gem/doorkeeper/pull/1488 is merged and released'

            user = create(:user)

            request_oauth_token(user, basic_auth_header(client.uid, 'invalid secret'))

            expect(response).to have_gitlab_http_status(:unauthorized)
            expect(json_response['error']).to eq('invalid_client')
          end
        end
      end
    end

    shared_examples 'does not create an access token' do
      let(:user) { create(:user) }

      it { expect(response).to have_gitlab_http_status(:bad_request) }
    end

    context 'when user is blocked' do
      before do
        user.block

        request_oauth_token(user, client_basic_auth_header(client))
      end

      include_examples 'does not create an access token'
    end

    context 'when user is ldap_blocked' do
      before do
        user.ldap_block

        request_oauth_token(user, client_basic_auth_header(client))
      end

      include_examples 'does not create an access token'
    end

    context 'when user account is not confirmed' do
      before do
        user.update!(confirmed_at: nil)

        request_oauth_token(user, client_basic_auth_header(client))
      end

      include_examples 'does not create an access token'
    end
  end
end
