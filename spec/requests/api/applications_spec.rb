# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Applications, :aggregate_failures, :api, feature_category: :system_access do
  let_it_be(:admin) { create(:admin) }
  let_it_be(:user) { create(:user) }
  let_it_be(:scopes) { 'api' }
  let_it_be(:path) { "/applications" }
  let!(:application) { create(:application, name: 'another_application', owner: nil, redirect_uri: 'http://other_application.url', scopes: scopes) }

  describe 'POST /applications' do
    it_behaves_like 'POST request permissions for admin mode' do
      let(:params) { { name: 'application_name', redirect_uri: 'http://application.url', scopes: 'api' } }
    end

    context 'authenticated and authorized user' do
      it 'creates and returns an OAuth application' do
        expect do
          post api(path, admin, admin_mode: true), params: { name: 'application_name', redirect_uri: 'http://application.url', scopes: scopes }
        end.to change { Doorkeeper::Application.count }.by 1

        application = Doorkeeper::Application.find_by(name: 'application_name', redirect_uri: 'http://application.url')

        expect(json_response).to be_a Hash
        expect(json_response['application_id']).to eq application.uid
        expect(application.secret_matches?(json_response['secret'])).to eq(true)
        expect(json_response['callback_url']).to eq application.redirect_uri
        expect(json_response['confidential']).to eq application.confidential
        expect(application.scopes.to_s).to eq('api')
      end

      it 'does not allow creating an application with the wrong redirect_uri format' do
        expect do
          post api(path, admin, admin_mode: true), params: { name: 'application_name', redirect_uri: 'http://', scopes: scopes }
        end.not_to change { Doorkeeper::Application.count }

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response).to be_a Hash
        expect(json_response['message']['redirect_uri'][0]).to eq('must be a valid URI.')
      end

      it 'does not allow creating an application with a forbidden URI format' do
        expect do
          post api(path, admin, admin_mode: true), params: { name: 'application_name', redirect_uri: 'javascript://alert()', scopes: scopes }
        end.not_to change { Doorkeeper::Application.count }

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response).to be_a Hash
        expect(json_response['message']['redirect_uri'][0]).to eq('is forbidden by the server.')
      end

      it 'does not allow creating an application without a name' do
        expect do
          post api(path, admin, admin_mode: true), params: { redirect_uri: 'http://application.url', scopes: scopes }
        end.not_to change { Doorkeeper::Application.count }

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response).to be_a Hash
        expect(json_response['error']).to eq('name is missing')
      end

      it 'does not allow creating an application without a redirect_uri' do
        expect do
          post api(path, admin, admin_mode: true), params: { name: 'application_name', scopes: scopes }
        end.not_to change { Doorkeeper::Application.count }

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response).to be_a Hash
        expect(json_response['error']).to eq('redirect_uri is missing')
      end

      it 'does not allow creating an application without specifying `scopes`' do
        expect do
          post api(path, admin, admin_mode: true), params: { name: 'application_name', redirect_uri: 'http://application.url' }
        end.not_to change { Doorkeeper::Application.count }

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response).to be_a Hash
        expect(json_response['error']).to eq('scopes is missing, scopes is empty')
      end

      it 'does not allow creating an application with blank `scopes`' do
        expect do
          post api(path, admin, admin_mode: true), params: { name: 'application_name', redirect_uri: 'http://application.url', scopes: '' }
        end.not_to change { Doorkeeper::Application.count }

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response['error']).to eq('scopes is empty')
      end

      it 'does not allow creating an application with invalid `scopes`' do
        expect do
          post api(path, admin, admin_mode: true), params: { name: 'application_name', redirect_uri: 'http://application.url', scopes: 'non_existent_scope' }
        end.not_to change { Doorkeeper::Application.count }

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response['message']['scopes'][0]).to eq('doesn\'t match configured on the server.')
      end

      context 'multiple scopes' do
        it 'creates an application with multiple `scopes` when each scope specified is seperated by a space' do
          expect do
            post api(path, admin, admin_mode: true), params: { name: 'application_name', redirect_uri: 'http://application.url', scopes: 'api read_user' }
          end.to change { Doorkeeper::Application.count }.by 1

          application = Doorkeeper::Application.last

          expect(response).to have_gitlab_http_status(:created)
          expect(application.scopes.to_s).to eq('api read_user')
        end

        it 'does not allow creating an application with multiple `scopes` when one of the scopes is invalid' do
          expect do
            post api(path, admin, admin_mode: true), params: { name: 'application_name', redirect_uri: 'http://application.url', scopes: 'api non_existent_scope' }
          end.not_to change { Doorkeeper::Application.count }

          expect(response).to have_gitlab_http_status(:bad_request)
          expect(json_response['message']['scopes'][0]).to eq('doesn\'t match configured on the server.')
        end
      end

      it 'defaults to creating an application with confidential' do
        expect do
          post api(path, admin, admin_mode: true), params: { name: 'application_name', redirect_uri: 'http://application.url', scopes: scopes, confidential: nil }
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
          post api(path, user), params: { name: 'application_name', redirect_uri: 'http://application.url', scopes: scopes }
        end.not_to change { Doorkeeper::Application.count }
      end
    end

    context 'non-authenticated user' do
      it 'does not create application' do
        expect do
          post api(path), params: { name: 'application_name', redirect_uri: 'http://application.url' }
        end.not_to change { Doorkeeper::Application.count }

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end
  end

  describe 'GET /applications' do
    it_behaves_like 'GET request permissions for admin mode'

    it 'can list application' do
      get api(path, admin, admin_mode: true)

      expect(json_response).to be_a(Array)
    end

    context 'non-authenticated user' do
      it 'cannot list application' do
        get api(path)

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end
  end

  describe 'DELETE /applications/:id' do
    context 'user authorization' do
      let!(:path) { "/applications/#{application.id}" }

      it_behaves_like 'DELETE request permissions for admin mode'
    end

    context 'authenticated and authorized user' do
      it 'can delete an application' do
        expect do
          delete api("#{path}/#{application.id}", admin, admin_mode: true)
        end.to change { Doorkeeper::Application.count }.by(-1)
      end

      it 'cannot delete non-existing application' do
        delete api("#{path}/#{non_existing_record_id}", admin, admin_mode: true)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'non-authenticated user' do
      it 'cannot delete an application' do
        delete api("#{path}/#{application.id}")

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end
  end

  describe "POST /application/:id/renew-secret" do
    let(:path) { "/applications/#{application.id}/renew-secret" }

    context 'user authorization' do
      it_behaves_like 'POST request permissions for admin mode' do
        let(:params) { {} }
      end
    end

    context 'authenticated and authorized user' do
      it 'can renew a secret token' do
        application = Doorkeeper::Application.last
        post api(path, admin, admin_mode: true), params: {}

        expect(response).to have_gitlab_http_status(:created)
        expect(json_response['secret']).not_to be nil
        expect(application.secret_matches?(json_response['secret'])).not_to eq(true)
      end

      it 'return 404 when application_id not found' do
        post api("/applications/#{non_existing_record_id}/renew-secret", admin, admin_mode: true)
        expect(response).to have_gitlab_http_status(:not_found)
      end

      it 'return 400 when the operation is failed' do
        allow_next_instance_of(ApplicationsFinder) do |finder|
          allow(finder).to receive(:execute).and_return(application)
        end
        allow(application).to receive(:renew_secret).and_return(true)
        allow(application).to receive(:valid?).and_return(false)
        errors = ActiveModel::Errors.new(application)
        errors.add(:name, 'Error 1')
        allow(application).to receive(:errors).and_return(errors)

        post api(path, admin, admin_mode: true)

        expect(response).to have_gitlab_http_status(:bad_request)
      end
    end

    context 'non-authenticated user' do
      it 'cannot renew a secret token' do
        post api(path)

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end
  end
end
