# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::UrlController, feature_category: :importers do
  let_it_be(:user) { create(:user, :with_namespace) }

  before do
    login_as(user)
  end

  describe 'GET #new' do
    context 'when import_by_url_new_page feature flag is enabled' do
      before do
        stub_feature_flags(import_by_url_new_page: true)
      end

      it 'renders the new template' do
        stub_licensed_features(repository_mirrors: true) if Gitlab.ee?

        get new_import_url_path

        expect(response).to have_gitlab_http_status(:ok)
      end
    end

    context 'when import_by_url_new_page feature flag is disabled' do
      before do
        stub_feature_flags(import_by_url_new_page: false)
      end

      it 'returns 404' do
        get new_import_url_path

        expect(response).to have_gitlab_http_status(:not_found)
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
