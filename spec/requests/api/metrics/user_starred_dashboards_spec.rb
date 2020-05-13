# frozen_string_literal: true

require 'spec_helper'

describe API::Metrics::UserStarredDashboards do
  let_it_be(:user) { create(:user) }
  let!(:project) { create(:project, :private, :repository, :custom_repo, namespace: user.namespace, files: { dashboard => dashboard_yml }) }
  let(:dashboard_yml) { fixture_file('lib/gitlab/metrics/dashboard/sample_dashboard.yml') }
  let(:dashboard) { '.gitlab/dashboards/find&seek.yml' }
  let(:params) do
    {
      user: user,
      project: project,
      dashboard_path: CGI.escape(dashboard)
    }
  end

  describe 'POST /projects/:id/metrics/user_starred_dashboards' do
    let(:url) { "/projects/#{project.id}/metrics/user_starred_dashboards" }

    before do
      project.add_reporter(user)
    end

    context 'with correct permissions' do
      context 'with valid parameters' do
        context 'dashboard_path as url param url escaped' do
          it 'creates a new annotation', :aggregate_failures do
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
              user: user,
              project: project,
              dashboard_path: dashboard
            }
          end

          it 'creates a new annotation', :aggregate_failures do
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
end
