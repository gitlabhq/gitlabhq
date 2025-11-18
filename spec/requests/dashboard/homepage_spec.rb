# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Dashboard homepage', feature_category: :notifications do
  let_it_be(:user) { create(:user) }

  before do
    sign_in(user)
    stub_feature_flags(personal_homepage: true, organization_scoped_paths: false)
  end

  describe 'GET /dashboard/home' do
    it 'returns success' do
      get home_dashboard_path

      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to render_template('root/index')
    end
  end

  describe 'GET /' do
    context 'when using the default homepage (with flipped mapping)' do
      it 'renders the homepage template' do
        get root_path

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to render_template('root/index')
      end
    end

    context 'when explicitly setting dashboard to homepage (with flipped mapping)' do
      let_it_be(:homepage_user) { create(:user, dashboard: :homepage) }

      before do
        sign_in(homepage_user)
      end

      it 'renders the homepage template' do
        get root_path

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to render_template('root/index')
      end
    end
  end
end
