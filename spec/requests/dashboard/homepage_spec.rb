# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Dashboard homepage', feature_category: :notifications do
  let_it_be(:user) { create(:user) }

  before do
    sign_in(user)
  end

  describe 'GET /dashboard/home' do
    it 'returns success' do
      get home_dashboard_path

      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to render_template('root/index')
    end

    # Both this action and RootController#index render root/index, so the widget's
    # feature flag has to be pushed from both or the widget silently disappears here.
    it 'pushes the merge requests widget feature flag to the frontend' do
      get home_dashboard_path

      expect(response.body).to have_pushed_frontend_feature_flags(homepageMergeRequestsWidget: true)
    end

    context 'when the homepage_merge_requests_widget flag is disabled' do
      before do
        stub_feature_flags(homepage_merge_requests_widget: false)
      end

      it 'pushes the flag as disabled' do
        get home_dashboard_path

        expect(response.body).to have_pushed_frontend_feature_flags(
          homepageMergeRequestsWidget: false
        )
      end
    end
  end

  describe 'GET /' do
    context 'when using the default homepage (with flipped mapping)' do
      it 'renders the homepage template' do
        get root_path

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to render_template('root/index')
      end

      it 'pushes the merge requests widget feature flag to the frontend' do
        get root_path

        expect(response.body).to have_pushed_frontend_feature_flags(
          homepageMergeRequestsWidget: true
        )
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
