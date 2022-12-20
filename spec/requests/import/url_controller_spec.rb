# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::UrlController, feature_category: :importers do
  let_it_be(:user) { create(:user) }

  before do
    login_as(user)
  end

  describe 'POST #validate' do
    it 'reports success when service reports success status' do
      allow_next_instance_of(Import::ValidateRemoteGitEndpointService) do |validate_endpoint_service|
        allow(validate_endpoint_service).to receive(:execute).and_return(ServiceResponse.success)
      end

      post import_url_validate_path, params: { url: 'https://fake.repo' }

      expect(json_response).to eq({ 'success' => true })
    end

    it 'exposes error message when service reports error' do
      expect_next_instance_of(Import::ValidateRemoteGitEndpointService) do |validate_endpoint_service|
        expect(validate_endpoint_service).to receive(:execute).and_return(ServiceResponse.error(message: 'foobar'))
      end

      post import_url_validate_path, params: { url: 'https://fake.repo' }

      expect(json_response).to eq({ 'success' => false, 'message' => 'foobar' })
    end

    context 'with an anonymous user' do
      before do
        sign_out(user)
      end

      it 'redirects to sign-in page' do
        post import_url_validate_path

        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
