# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'metrics dashboard page' do
  let_it_be(:project) { create(:project) }
  let_it_be(:environment) { create(:environment, project: project) }
  let_it_be(:environment2) { create(:environment, project: project) }
  let_it_be(:user) { project.owner }

  before do
    project.add_developer(user)
    login_as(user)
  end

  describe 'GET /:namespace/:project/-/metrics' do
    it 'returns 200' do
      send_request
      expect(response).to have_gitlab_http_status(:ok)
    end

    it 'assigns environment' do
      send_request
      expect(assigns(:environment).id).to eq(environment.id)
    end

    context 'with anonymous user and public dashboard visibility' do
      let(:anonymous_user) { create(:user) }
      let(:project) do
        create(:project, :public, metrics_dashboard_access_level: 'enabled')
      end

      before do
        login_as(anonymous_user)
      end

      it 'returns 200' do
        send_request
        expect(response).to have_gitlab_http_status(:ok)
      end
    end
  end

  describe 'GET /:namespace/:project/-/metrics?environment=:environment.id' do
    it 'returns 200' do
      send_request(environment: environment2.id)
      expect(response).to have_gitlab_http_status(:ok)
    end

    it 'assigns query param environment' do
      send_request(environment: environment2.id)
      expect(assigns(:environment).id).to eq(environment2.id)
    end

    context 'when query param environment does not exist' do
      it 'responds with 404' do
        send_request(environment: 99)
        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe 'GET /:namespace/:project/-/metrics/:dashboard_path' do
    let(:dashboard_path) { '.gitlab/dashboards/dashboard_path.yml' }

    it 'returns 200' do
      send_request(dashboard_path: dashboard_path)
      expect(response).to have_gitlab_http_status(:ok)
    end

    it 'assigns environment' do
      send_request(dashboard_path: dashboard_path)
      expect(assigns(:environment).id).to eq(environment.id)
    end
  end

  describe 'GET :/namespace/:project/-/metrics/:dashboard_path?environment=:environment.id' do
    let(:dashboard_path) { '.gitlab/dashboards/dashboard_path.yml' }

    it 'returns 200' do
      send_request(dahboard_path: dashboard_path, environment: environment.id)
      expect(response).to have_gitlab_http_status(:ok)
    end

    it 'assigns query param environment' do
      send_request(dashboard_path: dashboard_path, environment: environment2.id)
      expect(assigns(:environment).id).to eq(environment2.id)
    end

    context 'when query param environment does not exist' do
      it 'responds with 404' do
        send_request(dashboard_path: dashboard_path, environment: 99)
        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe 'GET :/namespace/:project/-/metrics/:page' do
    it 'returns 200 with path param page' do
      # send_request(page: 'panel/new') cannot be used because it encodes '/'
      get "#{dashboard_route}/panel/new"

      expect(response).to have_gitlab_http_status(:ok)
    end

    it 'returns 200 with dashboard and path param page' do
      # send_request(page: 'panel/new') cannot be used because it encodes '/'
      get "#{dashboard_route(dashboard_path: 'dashboard.yml')}/panel/new"

      expect(response).to have_gitlab_http_status(:ok)
    end
  end

  def send_request(params = {})
    get dashboard_route(params)
  end

  def dashboard_route(params = {})
    namespace_project_metrics_dashboard_path(namespace_id: project.namespace, project_id: project, **params)
  end
end
