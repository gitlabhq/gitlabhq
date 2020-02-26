# frozen_string_literal: true

require 'spec_helper'

describe 'OAuth tokens' do
  context 'Resource Owner Password Credentials' do
    def request_oauth_token(user)
      post '/oauth/token', params: { username: user.username, password: user.password, grant_type: 'password' }
    end

    context 'when user has 2FA enabled' do
      it 'does not create an access token' do
        user = create(:user, :two_factor)

        request_oauth_token(user)

        expect(response).to have_gitlab_http_status(:unauthorized)
        expect(json_response['error']).to eq('invalid_grant')
      end
    end

    context 'when user does not have 2FA enabled' do
      it 'creates an access token' do
        user = create(:user)

        request_oauth_token(user)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['access_token']).not_to be_nil
      end
    end

    shared_examples 'does not create an access token' do
      let(:user) { create(:user) }

      it { expect(response).to have_gitlab_http_status(:unauthorized) }
    end

    context 'when user is blocked' do
      before do
        user.block

        request_oauth_token(user)
      end

      include_examples 'does not create an access token'
    end

    context 'when user is ldap_blocked' do
      before do
        user.ldap_block

        request_oauth_token(user)
      end

      include_examples 'does not create an access token'
    end

    context 'when user account is not confirmed' do
      before do
        user.update!(confirmed_at: nil)

        request_oauth_token(user)
      end

      include_examples 'does not create an access token'
    end
  end
end
