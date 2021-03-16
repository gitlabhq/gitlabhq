# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Applications, :api do
  let(:admin_user) { create(:user, admin: true) }
  let(:user) { create(:user, admin: false) }
  let!(:application) { create(:application, name: 'another_application', owner: nil, redirect_uri: 'http://other_application.url', scopes: '') }

  describe 'POST /applications' do
    context 'authenticated and authorized user' do
      it 'creates and returns an OAuth application' do
        expect do
          post api('/applications', admin_user), params: { name: 'application_name', redirect_uri: 'http://application.url', scopes: '' }
        end.to change { Doorkeeper::Application.count }.by 1

        application = Doorkeeper::Application.find_by(name: 'application_name', redirect_uri: 'http://application.url')

        expect(response).to have_gitlab_http_status(:created)
        expect(json_response).to be_a Hash
        expect(json_response['application_id']).to eq application.uid
        expect(json_response['secret']).to eq application.secret
        expect(json_response['callback_url']).to eq application.redirect_uri
        expect(json_response['confidential']).to eq application.confidential
      end

      it 'does not allow creating an application with the wrong redirect_uri format' do
        expect do
          post api('/applications', admin_user), params: { name: 'application_name', redirect_uri: 'http://', scopes: '' }
        end.not_to change { Doorkeeper::Application.count }

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response).to be_a Hash
        expect(json_response['message']['redirect_uri'][0]).to eq('must be a valid URI.')
      end

      it 'does not allow creating an application with a forbidden URI format' do
        expect do
          post api('/applications', admin_user), params: { name: 'application_name', redirect_uri: 'javascript://alert()', scopes: '' }
        end.not_to change { Doorkeeper::Application.count }

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response).to be_a Hash
        expect(json_response['message']['redirect_uri'][0]).to eq('is forbidden by the server.')
      end

      it 'does not allow creating an application without a name' do
        expect do
          post api('/applications', admin_user), params: { redirect_uri: 'http://application.url', scopes: '' }
        end.not_to change { Doorkeeper::Application.count }

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response).to be_a Hash
        expect(json_response['error']).to eq('name is missing')
      end

      it 'does not allow creating an application without a redirect_uri' do
        expect do
          post api('/applications', admin_user), params: { name: 'application_name', scopes: '' }
        end.not_to change { Doorkeeper::Application.count }

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response).to be_a Hash
        expect(json_response['error']).to eq('redirect_uri is missing')
      end

      it 'does not allow creating an application without scopes' do
        expect do
          post api('/applications', admin_user), params: { name: 'application_name', redirect_uri: 'http://application.url' }
        end.not_to change { Doorkeeper::Application.count }

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response).to be_a Hash
        expect(json_response['error']).to eq('scopes is missing')
      end

      it 'defaults to creating an application with confidential' do
        expect do
          post api('/applications', admin_user), params: { name: 'application_name', redirect_uri: 'http://application.url', scopes: '', confidential: nil }
        end.to change { Doorkeeper::Application.count }.by(1)

        expect(response).to have_gitlab_http_status(:created)
        expect(json_response).to be_a Hash
        expect(json_response['callback_url']).to eq('http://application.url')
        expect(json_response['confidential']).to be true
      end
    end

    context 'authorized user without authorization' do
      it 'does not create application' do
        expect do
          post api('/applications', user), params: { name: 'application_name', redirect_uri: 'http://application.url', scopes: '' }
        end.not_to change { Doorkeeper::Application.count }

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'non-authenticated user' do
      it 'does not create application' do
        expect do
          post api('/applications'), params: { name: 'application_name', redirect_uri: 'http://application.url' }
        end.not_to change { Doorkeeper::Application.count }

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end
  end

  describe 'GET /applications' do
    context 'authenticated and authorized user' do
      it 'can list application' do
        get api('/applications', admin_user)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to be_a(Array)
      end
    end

    context 'authorized user without authorization' do
      it 'cannot list application' do
        get api('/applications', user)

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'non-authenticated user' do
      it 'cannot list application' do
        get api('/applications')

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end
  end

  describe 'DELETE /applications/:id' do
    context 'authenticated and authorized user' do
      it 'can delete an application' do
        expect do
          delete api("/applications/#{application.id}", admin_user)
        end.to change { Doorkeeper::Application.count }.by(-1)

        expect(response).to have_gitlab_http_status(:no_content)
      end

      it 'cannot delete non-existing application' do
        delete api("/applications/#{non_existing_record_id}", admin_user)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'authorized user without authorization' do
      it 'cannot delete an application' do
        delete api("/applications/#{application.id}", user)

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'non-authenticated user' do
      it 'cannot delete an application' do
        delete api("/applications/#{application.id}")

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end
  end
end
