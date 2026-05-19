# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::UrlController, feature_category: :importers do
  let_it_be(:user) { create(:user, :with_namespace) }

  before do
    login_as(user)
  end

  describe 'GET #new' do
    it 'renders the new template' do
      get new_import_url_path

      expect(response).to have_gitlab_http_status(:ok)
    end

    context 'when user is not allowed to import projects' do
      before do
        allow(Ability).to receive(:allowed?).and_call_original
        allow(Ability).to receive(:allowed?)
          .with(user, :import_projects, user.namespace)
          .and_return(false)
      end

      it 'returns access denied' do
        get new_import_url_path

        expect(response).to have_gitlab_http_status(:forbidden)
        expect(response.body).to match(/You do not have permission to import projects/)
      end
    end

    context 'when user is allowed to create projects in this namespace' do
      let(:namespace) { create(:namespace, owner: user) }

      it 'includes namespace data in the response' do
        get new_import_url_path(namespace_id: namespace.id)
        expect(response).to have_gitlab_http_status(:ok)
        expect(response.body).to include("data-namespace-id=\"#{namespace.id}\"")
      end
    end

    context 'when user is not allowed to create projects in this namespace' do
      let(:new_namespace) { create(:namespace) }

      it 'does not include namespace in response' do
        get new_import_url_path(namespace_id: new_namespace.id)
        expect(response).to have_gitlab_http_status(:ok)
        expect(response.body).to include('data-namespace-id=""')
      end
    end

    context 'without namespace_id param' do
      it 'does not include namespace in the response' do
        get new_import_url_path
        expect(response).to have_gitlab_http_status(:ok)
        expect(response.body).to include('data-namespace-id=""')
      end
    end
  end

  describe 'POST #validate' do
    it 'reports success when service reports success status' do
      allow_next_instance_of(Import::ValidateRemoteGitEndpointService) do |validate_endpoint_service|
        allow(validate_endpoint_service).to receive(:execute).and_return(ServiceResponse.success)
      end

      post validate_import_url_path, params: { url: 'https://fake.repo' }

      expect(json_response).to eq({ 'success' => true })
    end

    it 'exposes error message when service reports error' do
      expect_next_instance_of(Import::ValidateRemoteGitEndpointService) do |validate_endpoint_service|
        expect(validate_endpoint_service).to receive(:execute).and_return(ServiceResponse.error(message: 'foobar'))
      end

      post validate_import_url_path, params: { url: 'https://fake.repo' }

      expect(json_response).to eq({ 'success' => false, 'message' => 'foobar' })
    end

    context 'with an anonymous user' do
      before do
        sign_out(user)
      end

      it 'redirects to sign-in page' do
        post validate_import_url_path

        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
