# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'OAuth Tokens requests', feature_category: :system_access do
  let(:user) { create :user }
  let(:application) { create :oauth_application, scopes: 'api' }
  let(:grant_type) { 'authorization_code' }
  let(:refresh_token) { nil }

  def request_access_token(user)
    post '/oauth/token',
      params: {
        grant_type: grant_type,
        code: generate_access_grant(user).token,
        redirect_uri: application.redirect_uri,
        client_id: application.uid,
        client_secret: application.secret,
        refresh_token: refresh_token

      }
  end

  def request_token_info(token, headers: {})
    get '/oauth/token/info', params: {}, headers: { 'Authorization' => "Bearer #{token}" }.merge(headers)
  end

  def generate_access_grant(user)
    create(:oauth_access_grant, application: application, resource_owner_id: user.id)
  end

  context 'when there is already a token for the application' do
    let!(:existing_token) { create(:oauth_access_token, application: application, resource_owner_id: user.id) }

    shared_examples 'issues a new token' do
      it 'issues a new token' do
        expect do
          request_access_token(user)
        end.to change { Doorkeeper::AccessToken.count }.from(1).to(2)

        expect(json_response['access_token']).not_to eq existing_token.token
        expect(json_response['refresh_token']).not_to eq existing_token.refresh_token
      end
    end

    shared_examples 'revokes previous token' do
      it 'revokes previous token' do
        expect { request_access_token(user) }.to(
          change { existing_token.reload.revoked_at }.from(nil))
      end
    end

    it 'allows cross origin for token info' do
      request_token_info(existing_token.token, headers: { 'Origin' => 'http://notgitlab.example.com' })

      expect(response.headers['Access-Control-Allow-Origin']).to eq '*'
      expect(response.headers['Access-Control-Allow-Methods']).to eq 'GET, HEAD, OPTIONS'
      expect(response.headers['Access-Control-Allow-Headers']).to be_nil
      expect(response.headers['Access-Control-Allow-Credentials']).to be_nil
    end

    context 'and the request is done by the resource owner' do
      context 'with authorization code grant type' do
        include_examples 'issues a new token'

        it 'does not revoke previous token' do
          request_access_token(user)

          expect(existing_token.reload.revoked_at).to be_nil
        end
      end

      context 'with refresh token grant type' do
        let(:grant_type) { 'refresh_token' }
        let(:refresh_token) { existing_token.refresh_token }

        include_examples 'issues a new token'
        include_examples 'revokes previous token'

        context 'expired refresh token' do
          let!(:existing_token) do
            create(
              :oauth_access_token,
              application: application,
              resource_owner_id: user.id,
              created_at: 10.minutes.ago,
              expires_in: 5
            )
          end

          include_examples 'issues a new token'
          include_examples 'revokes previous token'
        end

        context 'revoked refresh token' do
          let!(:existing_token) do
            create(:oauth_access_token,
              application: application,
              resource_owner_id: user.id,
              created_at: 2.hours.ago,
              revoked_at: 1.hour.ago,
              expires_in: 5)
          end

          it 'does not issue a new token' do
            request_access_token(user)

            expect(json_response['error']).to eq('invalid_grant')
          end
        end
      end
    end
  end

  context 'when there is no token stored for the application' do
    it 'generates and returns a new token' do
      expect do
        request_access_token(user)
      end.to change { Doorkeeper::AccessToken.count }.by(1)

      expect(json_response['access_token']).not_to be_nil
      expect(json_response['expires_in']).not_to be_nil
    end
  end
end
