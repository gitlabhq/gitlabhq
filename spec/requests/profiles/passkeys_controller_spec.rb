# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Profiles::PasskeysController, feature_category: :system_access do
  let_it_be(:current_user) { create(:user, :with_namespace) }

  before do
    sign_in(current_user)
  end

  shared_examples 'page is found' do
    it 'returns a 200 status code' do
      expect(response).to have_gitlab_http_status(:ok)
    end
  end

  shared_examples 'page has no content' do
    it 'returns a 200 status code' do
      expect(response).to have_gitlab_http_status(:no_content)
    end
  end

  shared_examples 'page is not found' do
    it 'has correct status' do
      expect(response).to have_gitlab_http_status(:not_found)
    end
  end

  context 'when passkeys flag is off' do
    before do
      stub_feature_flags(passkeys: false)
    end

    describe 'GET new' do
      before do
        get new_profile_passkey_path
      end

      it_behaves_like 'page is not found'
    end

    describe 'POST create' do
      before do
        post profile_passkeys_path
      end

      it_behaves_like 'page is not found'
    end

    describe 'DELETE destroy' do
      before do
        delete profile_passkey_path(1)
      end

      it_behaves_like 'page is not found'
    end
  end

  context 'when passkeys flag is on' do
    describe 'GET new' do
      before do
        get new_profile_passkey_path
      end

      it_behaves_like 'page is found'
    end

    describe 'POST create' do
      before do
        post profile_passkeys_path
      end

      it_behaves_like 'page has no content'
    end

    describe 'DELETE destroy' do
      before do
        delete profile_passkey_path(1)
      end

      it_behaves_like 'page has no content'
    end
  end
end
