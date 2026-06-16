# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::UserApplications, :aggregate_failures, feature_category: :system_access do
  let_it_be(:user) { create(:user) }
  let_it_be(:application) { create(:oauth_application, owner: user) }
  let_it_be(:other_application) { create(:oauth_application) } # owner: nil (admin application)

  describe 'GET /user/applications' do
    it_behaves_like 'authorizing granular token permissions', :read_oauth_application do
      let(:boundary_object) { :user }
      let(:request) { get api('/user/applications', personal_access_token: pat) }
    end

    it 'returns the user applications' do
      get api('/user/applications', user)

      expect(response).to have_gitlab_http_status(:ok)
    end

    it 'returns 401 for unauthorized user' do
      get api('/user/applications')

      expect(response).to have_gitlab_http_status(:unauthorized)
    end
  end

  describe 'GET /user/applications/:id' do
    it_behaves_like 'authorizing granular token permissions', :read_oauth_application do
      let(:boundary_object) { :user }
      let(:request) { get api("/user/applications/#{application.id}", personal_access_token: pat) }
    end

    it 'returns the application' do
      get api("/user/applications/#{application.id}", user)

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['id']).to eq(application.id)
    end

    it 'returns 403 for an application not owned by the user' do
      get api("/user/applications/#{other_application.id}", user)

      expect(response).to have_gitlab_http_status(:forbidden)
    end
  end

  describe 'POST /user/applications' do
    it_behaves_like 'authorizing granular token permissions', :create_oauth_application do
      let(:boundary_object) { :user }
      let(:request) do
        post api('/user/applications', personal_access_token: pat), params: {
          name: 'test_app',
          redirect_uri: 'https://example.com/callback',
          scopes: 'api',
          confidential: false
        }
      end
    end

    it 'creates a new application' do
      post api('/user/applications', user), params: {
        name: 'test_app',
        redirect_uri: 'https://example.com/callback',
        scopes: 'api',
        confidential: false
      }

      expect(response).to have_gitlab_http_status(:created)
      expect(json_response['application_name']).to eq('test_app')
      expect(json_response['callback_url']).to eq('https://example.com/callback')
      expect(json_response['confidential']).to be(false)
      expect(json_response['secret']).to be_present # should return secret on creation
      expect(json_response['application_id']).to be_present

      app = Authn::OauthApplication.last
      expect(app.owner).to eq(user)
    end

    it 'returns validation errors' do
      post api('/user/applications', user), params: {
        name: 'test_app',
        redirect_uri: 'invalid url',
        scopes: 'api'
      }

      expect(response).to have_gitlab_http_status(:bad_request)
      expect(json_response['message']['redirect_uri']).to be_present
    end
  end

  describe 'PUT /user/applications/:id' do
    it_behaves_like 'authorizing granular token permissions', :update_oauth_application do
      let(:boundary_object) { :user }
      let(:request) do
        put api("/user/applications/#{application.id}", personal_access_token: pat), params: {
          name: 'updated_app'
        }
      end
    end

    it 'updates an application' do
      put api("/user/applications/#{application.id}", user), params: {
        name: 'updated_app'
      }

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['application_name']).to eq('updated_app')

      expect(application.reload.name).to eq('updated_app')
    end

    it 'returns 403 for application not owned by user' do
      put api("/user/applications/#{other_application.id}", user), params: {
        name: 'updated_app'
      }

      expect(response).to have_gitlab_http_status(:forbidden)
      expect(other_application.reload.name).not_to eq('updated_app')
    end

    it 'returns validation errors on invalid update' do
      put api("/user/applications/#{application.id}", user), params: {
        name: ''
      }

      expect(response).to have_gitlab_http_status(:bad_request)
      expect(json_response['message']['name']).to be_present
    end
  end

  describe 'DELETE /user/applications/:id' do
    let(:app_to_delete) { create(:oauth_application, owner: user) }

    it_behaves_like 'authorizing granular token permissions', :delete_oauth_application do
      let(:boundary_object) { :user }
      let(:request) { delete api("/user/applications/#{app_to_delete.id}", personal_access_token: pat) }
    end

    it 'deletes the application' do
      delete api("/user/applications/#{app_to_delete.id}", user)

      expect(response).to have_gitlab_http_status(:no_content)
      expect(Authn::OauthApplication.find_by(id: app_to_delete.id)).to be_nil
    end

    it 'returns 403 for application not owned by user' do
      delete api("/user/applications/#{other_application.id}", user)

      expect(response).to have_gitlab_http_status(:forbidden)
      expect(Authn::OauthApplication.find_by(id: other_application.id)).not_to be_nil
    end
  end
end
