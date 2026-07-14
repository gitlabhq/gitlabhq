# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::GithubController, feature_category: :importers do
  describe 'GET details' do
    subject(:request) { get details_import_github_path }

    let_it_be(:user) { create(:user) }

    before do
      stub_application_setting(import_sources: ['github'])

      login_as(user)

      request
    end

    it 'responds with a 200 and shows the template', :aggregate_failures do
      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to render_template(:details)
    end
  end
end
