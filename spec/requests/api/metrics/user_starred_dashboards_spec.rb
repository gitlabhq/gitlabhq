# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Metrics::UserStarredDashboards do
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
      context 'with valid parameters' do
        context 'dashboard_path as url param url escaped' do
          it 'creates a new user starred metrics dashboard', :aggregate_failures do
            post api(url, user), params: params

            expect(response).to have_gitlab_http_status(:created)
            expect(json_response['project_id']).to eq(project.id)
            expect(json_response['user_id']).to eq(user.id)
            expect(json_response['dashboard_path']).to eq(dashboard)
          end
        end

        context 'dashboard_path in request body unescaped' do
          let(:params) do
            {
              dashboard_path: dashboard
            }
          end

          it 'creates a new user starred metrics dashboard', :aggregate_failures do
            post api(url, user), params: params

            expect(response).to have_gitlab_http_status(:created)
            expect(json_response['project_id']).to eq(project.id)
            expect(json_response['user_id']).to eq(user.id)
            expect(json_response['dashboard_path']).to eq(dashboard)
          end
        end
      end

      context 'with invalid parameters' do
        it 'returns error message' do
          post api(url, user), params: { dashboard_path: '' }

          expect(response).to have_gitlab_http_status(:bad_request)
          expect(json_response['error']).to eq('dashboard_path is empty')
        end

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
  end

  describe 'DELETE /projects/:id/metrics/user_starred_dashboards' do
    let_it_be(:user_starred_dashboard_1) { create(:metrics_users_starred_dashboard, user: user, project: project, dashboard_path: dashboard) }
    let_it_be(:user_starred_dashboard_2) { create(:metrics_users_starred_dashboard, user: user, project: project) }
    let_it_be(:other_user_starred_dashboard) { create(:metrics_users_starred_dashboard, project: project) }
    let_it_be(:other_project_starred_dashboard) { create(:metrics_users_starred_dashboard, user: user) }

    before do
      project.add_reporter(user)
    end

    context 'with correct permissions' do
      context 'with valid parameters' do
        context 'dashboard_path as url param url escaped' do
          it 'deletes given user starred metrics dashboard', :aggregate_failures do
            delete api(url, user), params: params

            expect(response).to have_gitlab_http_status(:ok)
            expect(json_response['deleted_rows']).to eq(1)
            expect(::Metrics::UsersStarredDashboard.all.pluck(:dashboard_path)).not_to include(dashboard)
          end
        end

        context 'dashboard_path in request body unescaped' do
          let(:params) do
            {
              dashboard_path: dashboard
            }
          end

          it 'deletes given user starred metrics dashboard', :aggregate_failures do
            delete api(url, user), params: params

            expect(response).to have_gitlab_http_status(:ok)
            expect(json_response['deleted_rows']).to eq(1)
            expect(::Metrics::UsersStarredDashboard.all.pluck(:dashboard_path)).not_to include(dashboard)
          end
        end

        context 'dashboard_path has not been specified' do
          it 'deletes all starred dashboards for that user within given project', :aggregate_failures do
            delete api(url, user), params: {}

            expect(response).to have_gitlab_http_status(:ok)
            expect(json_response['deleted_rows']).to eq(2)
            expect(::Metrics::UsersStarredDashboard.all).to contain_exactly(other_user_starred_dashboard, other_project_starred_dashboard)
          end
        end
      end

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
  end
end
