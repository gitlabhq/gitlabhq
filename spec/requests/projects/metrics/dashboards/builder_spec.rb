# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Projects::Metrics::Dashboards::BuilderController' do
  let_it_be(:project) { create(:project) }
  let_it_be(:environment) { create(:environment, project: project) }
  let_it_be(:user) { create(:user) }

  def send_request(params = {})
    post namespace_project_metrics_dashboards_builder_path(namespace_id: project.namespace, project_id: project, format: :json, **params)
  end

  describe 'POST /:namespace/:project/-/metrics/dashboards/builder' do
    context 'as anonymous user' do
      before do
        stub_feature_flags(metrics_dashboard_new_panel_page: true)
      end

      it 'redirects to sign in' do
        send_request

        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'as user with reporter access' do
      before do
        stub_feature_flags(metrics_dashboard_new_panel_page: true)
        project.add_guest(user)
        login_as(user)
      end

      it 'returns not found' do
        send_request

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'as logged in user' do
      before do
        project.add_developer(user)
        login_as(user)
      end

      context 'metrics_dashboard_new_panel_page is enabled' do
        before do
          stub_feature_flags(metrics_dashboard_new_panel_page: true)
        end

        it 'returns success' do
          send_request

          expect(response).to have_gitlab_http_status(:ok)
        end
      end

      context 'metrics_dashboard_new_panel_page is disabled' do
        before do
          stub_feature_flags(metrics_dashboard_new_panel_page: false)
        end

        it 'returns not found' do
          send_request

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end
  end
end
