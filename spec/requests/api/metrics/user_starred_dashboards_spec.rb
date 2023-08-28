# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Metrics::UserStarredDashboards, feature_category: :metrics do
  let_it_be(:user) { create(:user) }
  let_it_be(:dashboard_yml) { fixture_file('lib/gitlab/metrics/dashboard/sample_dashboard.yml') }
  let_it_be(:dashboard) { '.gitlab/dashboards/find&seek.yml' }
  let_it_be(:project) { create(:project, :private, :repository, :custom_repo, namespace: user.namespace, files: { dashboard => dashboard_yml }) }

  let(:url) { "/projects/#{project.id}/metrics/user_starred_dashboards" }
  let(:params) do
    {
      dashboard_path: CGI.escape(dashboard)
    }
  end

  describe 'POST /projects/:id/metrics/user_starred_dashboards' do
    before do
      project.add_reporter(user)
    end

    context 'with correct permissions' do
      context 'with invalid parameters' do
        context 'user is missing' do
          it 'returns 404 not found' do
            post api(url, nil), params: params

            expect(response).to have_gitlab_http_status(:not_found)
          end
        end

        context 'project is missing' do
          it 'returns 404 not found' do
            post api("/projects/#{project.id + 1}/user_starred_dashboards", user), params: params

            expect(response).to have_gitlab_http_status(:not_found)
          end
        end
      end
    end

    context 'without correct permissions' do
      it 'returns 404 not found' do
        post api(url, create(:user)), params: params

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when metrics dashboard feature is unavailable' do
      it 'returns 404 not found' do
        post api(url, user), params: params

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe 'DELETE /projects/:id/metrics/user_starred_dashboards' do
    before do
      project.add_reporter(user)
    end

    context 'with correct permissions' do
      context 'with invalid parameters' do
        context 'user is missing' do
          it 'returns 404 not found' do
            post api(url, nil), params: params

            expect(response).to have_gitlab_http_status(:not_found)
          end
        end

        context 'project is missing' do
          it 'returns 404 not found' do
            post api("/projects/#{project.id + 1}/user_starred_dashboards", user), params: params

            expect(response).to have_gitlab_http_status(:not_found)
          end
        end
      end
    end

    context 'without correct permissions' do
      it 'returns 404 not found' do
        post api(url, create(:user)), params: params

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when metrics dashboard feature is unavailable' do
      it 'returns 404 not found' do
        delete api(url, user), params: params

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end
end
