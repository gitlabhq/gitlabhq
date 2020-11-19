# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Projects::Metrics::Dashboards::BuilderController' do
  let_it_be(:project) { create(:project) }
  let_it_be(:environment) { create(:environment, project: project) }
  let_it_be(:user) { create(:user) }
  let_it_be(:valid_panel_yml) do
    <<~YML
    ---
    title: "Super Chart A1"
    type: "area-chart"
    y_label: "y_label"
    weight: 1
    max_value: 1
    metrics:
    - id: metric_a1
      query_range: |+
        avg(
          sum(
            container_memory_usage_bytes{
              container_name!="POD",
              pod_name=~"^{{ci_environment_slug}}-(.*)",
              namespace="{{kube_namespace}}",
              user_def_variable="{{user_def_variable}}"
            }
          ) by (job)
        ) without (job)
        /1024/1024/1024
      unit: unit
      label: Legend Label
    YML
  end

  let_it_be(:invalid_panel_yml) do
    <<~YML
    ---
    title: "Super Chart A1"
    type: "area-chart"
    y_label: "y_label"
    weight: 1
    max_value: 1
    YML
  end

  def send_request(params = {})
    post namespace_project_metrics_dashboards_builder_path(namespace_id: project.namespace, project_id: project, format: :json, **params)
  end

  describe 'POST /:namespace/:project/-/metrics/dashboards/builder' do
    context 'as anonymous user' do
      it 'redirects user to sign in page' do
        send_request

        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'as user with guest access' do
      before do
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

      context 'valid yaml panel is supplied' do
        it 'returns success' do
          send_request(panel_yaml: valid_panel_yml)

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response).to include('title' => 'Super Chart A1', 'type' => 'area-chart')
        end
      end

      context 'invalid yaml panel is supplied' do
        it 'returns unprocessable entity' do
          send_request(panel_yaml: invalid_panel_yml)

          expect(response).to have_gitlab_http_status(:unprocessable_entity)
          expect(json_response['message']).to eq('Each "panel" must define an array :metrics')
        end
      end

      context 'invalid panel_yaml is not a yaml string' do
        it 'returns unprocessable entity' do
          send_request(panel_yaml: 1)

          expect(response).to have_gitlab_http_status(:unprocessable_entity)
          expect(json_response['message']).to eq('Invalid configuration format')
        end
      end
    end
  end
end
