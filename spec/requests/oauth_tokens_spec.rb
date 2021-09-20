# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'OAuth Tokens requests' do
  let(:user) { create :user }
  let(:application) { create :oauth_application, scopes: 'api' }

  def request_access_token(user)
    post '/oauth/token',
      params: {
        grant_type: 'authorization_code',
        code: generate_access_grant(user).token,
        redirect_uri: application.redirect_uri,
        client_id: application.uid,
        client_secret: application.secret
      }
  end

  def generate_access_grant(user)
    create :oauth_access_grant, application: application, resource_owner_id: user.id
  end

  context 'when there is already a token for the application' do
    let!(:existing_token) { create :oauth_access_token, application: application, resource_owner_id: user.id }

    context 'and the request is done by the resource owner' do
      it 'reuses and returns the stored token' do
        expect do
          request_access_token(user)
        end.not_to change { Doorkeeper::AccessToken.count }

        expect(json_response['access_token']).to eq existing_token.token
      end
    end

    context 'and the request is done by a different user' do
      let(:other_user) { create :user }

      it 'generates and returns a different token for a different owner' do
        expect do
          request_access_token(other_user)
        end.to change { Doorkeeper::AccessToken.count }.by(1)

        expect(json_response['access_token']).not_to be_nil
      end
    end
  end

  context 'when there is no token stored for the application' do
    it 'generates and returns a new token' do
      expect do
        request_access_token(user)
      end.to change { Doorkeeper::AccessToken.count }.by(1)

      expect(json_response['access_token']).not_to be_nil
    end

    context 'when the application is configured to use expiring tokens' do
      before do
        application.update!(expire_access_tokens: true)
      end

      it 'generates an access token with an expiration' do
        request_access_token(user)

        expect(json_response['expires_in']).not_to be_nil
      end
    end

    context 'when the application is configured not to use expiring tokens' do
      before do
        application.update!(expire_access_tokens: false)
      end

      it 'generates an access token without an expiration' do
        request_access_token(user)

        expect(json_response.key?('expires_in')).to eq(false)
      end
    end
  end
end
