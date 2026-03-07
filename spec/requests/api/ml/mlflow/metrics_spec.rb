# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Ml::Mlflow::Metrics, feature_category: :mlops do
  let_it_be(:project) { create(:project) }
  let_it_be(:developer) { create(:user, developer_of: project) }
  let_it_be(:another_project) { create(:project).tap { |p| p.add_developer(developer) } }
  let_it_be(:experiment) do
    create(:ml_experiments, project: project)
  end

  let_it_be(:candidate) do
    create(:ml_candidates, experiment: experiment, project: project)
  end

  let_it_be(:tokens) do
    {
      write: create(:personal_access_token, scopes: %w[read_api api], user: developer),
      read: create(:personal_access_token, scopes: %w[read_api], user: developer),
      no_access: create(:personal_access_token, scopes: %w[read_user], user: developer),
      different_user: create(:personal_access_token, scopes: %w[read_api api], user: build(:user))
    }
  end

  let(:current_user) { developer }
  let(:access_token) { tokens[:read] }
  let(:headers) { { 'Authorization' => "Bearer #{access_token.token}" } }
  let(:project_id) { project.id }
  let(:default_params) { {} }
  let(:params) { default_params }
  let(:request) { get api(route), params: params, headers: headers }
  let(:json_response) { Gitlab::Json.safe_parse(api_response.body) }

  subject(:api_response) do
    request
    response
  end

  before do
    allow(Gitlab::Application.routes).to receive(:default_url_options)
      .and_return(protocol: 'http', host: 'www.example.com', script_name: '')
  end

  describe 'GET /projects/:id/ml/mlflow/api/2.0/mlflow/metrics/get-history' do
    let(:route) { "/projects/#{project_id}/ml/mlflow/api/2.0/mlflow/metrics/get-history" }
    let(:metric_key) { 'loss' }
    let(:default_params) { { run_id: candidate.eid.to_s, metric_key: metric_key } }

    let_it_be(:metrics) do
      Array.new(5) do |step|
        create(:ml_candidate_metrics,
          candidate: candidate,
          name: 'loss',
          value: 1.0 / (step + 1),
          step: step,
          tracked_at: (Time.now.to_i * 1000) + step)
      end
    end

    it 'returns metric history ordered by step', :aggregate_failures do
      is_expected.to have_gitlab_http_status(:ok)

      expect(json_response).to include('metrics')
      expect(json_response['metrics'].size).to eq(5)

      # Verify ordering by step
      steps = json_response['metrics'].pluck('step')
      expect(steps).to eq([0, 1, 2, 3, 4])

      # Verify metric values
      values = json_response['metrics'].pluck('value')
      expect(values).to eq([1.0, 0.5, (1.0 / 3), 0.25, 0.2])

      # Verify all metrics have the correct key
      json_response['metrics'].each do |metric|
        expect(metric['key']).to eq(metric_key)
        expect(metric).to include('timestamp', 'value', 'step')
      end
    end

    context 'with max_results parameter' do
      let(:params) { default_params.merge(max_results: 2) }

      it 'returns limited metrics and next_page_token', :aggregate_failures do
        is_expected.to have_gitlab_http_status(:ok)

        expect(json_response['metrics'].size).to eq(2)
        expect(json_response['next_page_token']).to be_present
      end
    end

    context 'with page_token parameter' do
      it 'returns the next page of metrics', :aggregate_failures do
        # First page
        get api(route), params: default_params.merge(max_results: 2), headers: headers
        first_response = Gitlab::Json.safe_parse(response.body)
        page_token = first_response['next_page_token']

        # Second page
        get api(route), params: default_params.merge(max_results: 2, page_token: page_token), headers: headers
        second_response = Gitlab::Json.safe_parse(response.body)

        expect(second_response['metrics'].size).to eq(2)
        expect(second_response['metrics'].pluck('step')).to eq([2, 3])
      end
    end

    context 'when metric does not exist' do
      let(:params) { default_params.merge(metric_key: 'nonexistent') }

      it 'returns empty metrics array', :aggregate_failures do
        is_expected.to have_gitlab_http_status(:ok)
        expect(json_response['metrics']).to be_empty
      end
    end

    context 'when run_id is not provided' do
      let(:params) { { metric_key: metric_key } }

      it 'returns Bad Request' do
        is_expected.to have_gitlab_http_status(:bad_request)
      end
    end

    context 'when metric_key is not provided' do
      let(:params) { { run_id: candidate.eid.to_s } }

      it 'returns Bad Request' do
        is_expected.to have_gitlab_http_status(:bad_request)
      end
    end

    context 'when run_id is invalid' do
      let(:params) { default_params.merge(run_id: non_existing_record_iid.to_s) }

      it 'returns Resource Does Not Exist', :aggregate_failures do
        is_expected.to have_gitlab_http_status(:not_found)
        expect(json_response).to include({ "error_code" => 'RESOURCE_DOES_NOT_EXIST' })
      end
    end

    context 'when run_id is not in the project' do
      let(:project_id) { another_project.id }

      it 'returns Resource Does Not Exist', :aggregate_failures do
        is_expected.to have_gitlab_http_status(:not_found)
        expect(json_response).to include({ "error_code" => 'RESOURCE_DOES_NOT_EXIST' })
      end
    end

    context 'with read-only token' do
      let(:access_token) { tokens[:read] }

      it 'allows access' do
        is_expected.to have_gitlab_http_status(:ok)
      end
    end

    context 'with no access token' do
      let(:access_token) { tokens[:no_access] }

      it 'returns Forbidden' do
        is_expected.to have_gitlab_http_status(:forbidden)
      end
    end
  end
end
