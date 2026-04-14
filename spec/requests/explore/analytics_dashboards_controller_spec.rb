# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Explore::AnalyticsDashboardsController, feature_category: :custom_dashboards_foundation do
  let_it_be(:user) { create(:user) }

  before do
    sign_in(user)
  end

  shared_examples 'basic get requests' do
    let(:path) do
      explore_analytics_dashboards_path
    end

    context 'with FF `explore_analytics_dashboards`' do
      before do
        stub_feature_flags(explore_analytics_dashboards: true)
      end

      it 'responds with 200' do
        get path

        expect(response).to have_gitlab_http_status(:ok)
      end
    end

    context 'without FF `explore_analytics_dashboards`' do
      before do
        stub_feature_flags(explore_analytics_dashboards: false)
      end

      it 'responds with 404' do
        get path

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe 'GET #index' do
    it_behaves_like 'basic get requests', :index
  end
end
