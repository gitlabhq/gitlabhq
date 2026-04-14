# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::Offline::ImportController, feature_category: :importers do
  let_it_be(:user) { create(:user) }

  before do
    login_as(user)
  end

  describe 'GET show' do
    context 'when offline_transfer_ui feature flag is disabled' do
      before do
        stub_feature_flags(offline_transfer_ui: false, offline_transfer_imports: true)
      end

      it 'returns 404' do
        get import_offline_import_path
        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when offline_transfer_imports feature flag is disabled' do
      before do
        stub_feature_flags(offline_transfer_ui: true, offline_transfer_imports: false)
      end

      it 'returns 404' do
        get import_offline_import_path
        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when both feature flags are enabled' do
      before do
        stub_feature_flags(offline_transfer_ui: true, offline_transfer_imports: true)
      end

      it 'renders the template' do
        get import_offline_import_path
        expect(response).to have_gitlab_http_status(:ok)
      end
    end
  end

  describe 'GET history' do
    before do
      stub_feature_flags(offline_transfer_ui: true, offline_transfer_imports: true)
    end

    it 'returns 404' do
      get history_import_offline_import_path
      expect(response).to have_gitlab_http_status(:not_found)
    end
  end
end
