# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Jira authorization requests' do
  let(:user) { create :user }
  let(:application) { create :oauth_application, scopes: 'api' }
  let(:redirect_uri) { oauth_jira_callback_url(host: "http://www.example.com") }

  def generate_access_grant
    create :oauth_access_grant, application: application, resource_owner_id: user.id, redirect_uri: redirect_uri
  end

  describe 'POST access_token' do
    let(:client_id) { application.uid }
    let(:client_secret) { application.secret }

    it 'returns values similar to a POST to /oauth/token' do
      post_data = {
        client_id: client_id,
        client_secret: client_secret
      }

      post '/oauth/token', params: post_data.merge({
        code: generate_access_grant.token,
        grant_type: 'authorization_code',
        redirect_uri: redirect_uri
      })
      oauth_response = json_response

      post '/login/oauth/access_token', params: post_data.merge({
        code: generate_access_grant.token
      })
      jira_response = response.body

      access_token, scope, token_type = oauth_response.values_at('access_token', 'scope', 'token_type')
      expect(jira_response).to eq("access_token=#{access_token}&scope=#{scope}&token_type=#{token_type}")
    end

    context 'when authorization fails' do
      before do
        post '/login/oauth/access_token', params: {
          client_id: client_id,
          client_secret: client_secret,
          code: try(:code) || generate_access_grant.token
        }
      end

      shared_examples 'an unauthorized request' do
        it 'returns 401' do
          expect(response).to have_gitlab_http_status(:unauthorized)
        end
      end

      context 'when client_id is invalid' do
        let(:client_id) { "invalid_id" }

        it_behaves_like 'an unauthorized request'
      end

      context 'when client_secret is invalid' do
        let(:client_secret) { "invalid_secret" }

        it_behaves_like 'an unauthorized request'
      end

      context 'when code is invalid' do
        let(:code) { "invalid_code" }

        it 'returns bad request' do
          expect(response).to have_gitlab_http_status(:bad_request)
        end
      end
    end
  end
end
