# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::GithubController, feature_category: :importers do
  describe 'GET details' do
    subject { get details_import_github_path }

    let_it_be(:user) { create(:user) }

    before do
      stub_application_setting(import_sources: ['github'])

      login_as(user)
    end

    context 'with feature enabled' do
      before do
        stub_feature_flags(import_details_page: true)

        subject
      end

      it 'responds with a 200 and shows the template' do
        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to render_template(:details)
      end
    end

    context 'with feature disabled' do
      before do
        stub_feature_flags(import_details_page: false)

        subject
      end

      it 'responds with a 404' do
        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end
end
