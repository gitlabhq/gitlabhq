# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Ml::Mlflow::Experiments, feature_category: :mlops do
  let_it_be(:project) { create(:project) }
  let_it_be(:developer) { create(:user).tap { |u| project.add_developer(u) } }
  let_it_be(:another_project) { build(:project).tap { |p| p.add_developer(developer) } }
  let_it_be(:experiment) do
    create(:ml_experiments, :with_metadata, project: project)
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
  let(:ff_value) { true }
  let(:access_token) { tokens[:write] }
  let(:headers) { { 'Authorization' => "Bearer #{access_token.token}" } }
  let(:project_id) { project.id }
  let(:default_params) { {} }
  let(:params) { default_params }
  let(:request) { get api(route), params: params, headers: headers }
  let(:json_response) { Gitlab::Json.parse(api_response.body) }
  let(:presented_experiment) do
    {
      'experiment_id' => experiment.iid.to_s,
      'name' => experiment.name,
      'lifecycle_stage' => 'active',
      'artifact_location' => 'not_implemented',
      'tags' => [
        {
          'key' => experiment.metadata[0].name,
          'value' => experiment.metadata[0].value
        },
        {
          'key' => experiment.metadata[1].name,
          'value' => experiment.metadata[1].value
        }
      ]
    }
  end

  subject(:api_response) do
    request
    response
  end

  before do
    stub_feature_flags(ml_experiment_tracking: ff_value)
  end

  describe 'GET /projects/:id/ml/mlflow/api/2.0/mlflow/experiments/get' do
    let(:experiment_iid) { experiment.iid.to_s }
    let(:route) { "/projects/#{project_id}/ml/mlflow/api/2.0/mlflow/experiments/get?experiment_id=#{experiment_iid}" }

    it 'returns the experiment', :aggregate_failures do
      is_expected.to have_gitlab_http_status(:ok)
      is_expected.to match_response_schema('ml/get_experiment')
      expect(json_response).to include({ 'experiment' => presented_experiment })
    end

    describe 'Error States' do
      context 'when has access' do
        context 'and experiment does not exist' do
          let(:experiment_iid) { non_existing_record_iid.to_s }

          it_behaves_like 'MLflow|Not Found - Resource Does Not Exist'
        end

        context 'and experiment_id is not passed' do
          let(:route) { "/projects/#{project_id}/ml/mlflow/api/2.0/mlflow/experiments/get" }

          it_behaves_like 'MLflow|Not Found - Resource Does Not Exist'
        end
      end

      it_behaves_like 'MLflow|shared error cases'
      it_behaves_like 'MLflow|Requires read_api scope'
    end
  end

  describe 'GET /projects/:id/ml/mlflow/api/2.0/mlflow/experiments/list' do
    let(:route) { "/projects/#{project_id}/ml/mlflow/api/2.0/mlflow/experiments/list" }

    it 'returns the experiments', :aggregate_failures do
      is_expected.to have_gitlab_http_status(:ok)
      is_expected.to match_response_schema('ml/list_experiments')
      expect(json_response).to include({ 'experiments' => [presented_experiment] })
    end

    context 'when there are no experiments' do
      let(:project_id) { another_project.id }

      it 'returns an empty list' do
        expect(json_response).to include({ 'experiments' => [] })
      end
    end

    describe 'Error States' do
      it_behaves_like 'MLflow|shared error cases'
      it_behaves_like 'MLflow|Requires read_api scope'
    end
  end

  describe 'GET /projects/:id/ml/mlflow/api/2.0/mlflow/experiments/get-by-name' do
    let(:experiment_name) { experiment.name }
    let(:route) do
      "/projects/#{project_id}/ml/mlflow/api/2.0/mlflow/experiments/get-by-name?experiment_name=#{experiment_name}"
    end

    it 'returns the experiment', :aggregate_failures do
      is_expected.to have_gitlab_http_status(:ok)
      is_expected.to match_response_schema('ml/get_experiment')
      expect(json_response).to include({ 'experiment' => presented_experiment })
    end

    describe 'Error States' do
      context 'when has access but experiment does not exist' do
        let(:experiment_name) { "random_experiment" }

        it_behaves_like 'MLflow|Not Found - Resource Does Not Exist'
      end

      context 'when has access but experiment_name is not passed' do
        let(:route) { "/projects/#{project_id}/ml/mlflow/api/2.0/mlflow/experiments/get-by-name" }

        it_behaves_like 'MLflow|Not Found - Resource Does Not Exist'
      end

      it_behaves_like 'MLflow|shared error cases'
      it_behaves_like 'MLflow|Requires read_api scope'
    end
  end

  describe 'POST /projects/:id/ml/mlflow/api/2.0/mlflow/experiments/create' do
    let(:route) do
      "/projects/#{project_id}/ml/mlflow/api/2.0/mlflow/experiments/create"
    end

    let(:params) { { name: 'new_experiment' } }
    let(:request) { post api(route), params: params, headers: headers }

    it 'creates the experiment', :aggregate_failures do
      is_expected.to have_gitlab_http_status(:ok)
      expect(json_response).to include('experiment_id')
    end

    describe 'Error States' do
      context 'when experiment name is not passed' do
        let(:params) { {} }

        it_behaves_like 'MLflow|Bad Request'
      end

      context 'when experiment name already exists' do
        let(:existing_experiment) do
          create(:ml_experiments, user: current_user, project: project)
        end

        let(:params) { { name: existing_experiment.name } }

        it "is Bad Request", :aggregate_failures do
          is_expected.to have_gitlab_http_status(:bad_request)

          expect(json_response).to include({ 'error_code' => 'RESOURCE_ALREADY_EXISTS' })
        end
      end

      context 'when project does not exist' do
        let(:route) { "/projects/#{non_existing_record_id}/ml/mlflow/api/2.0/mlflow/experiments/create" }

        it "is Not Found", :aggregate_failures do
          is_expected.to have_gitlab_http_status(:not_found)

          expect(json_response['message']).to eq('404 Project Not Found')
        end
      end

      it_behaves_like 'MLflow|shared error cases'
      it_behaves_like 'MLflow|Requires api scope'
    end
  end

  describe 'POST /projects/:id/ml/mlflow/api/2.0/mlflow/experiments/set-experiment-tag' do
    let(:route) { "/projects/#{project_id}/ml/mlflow/api/2.0/mlflow/experiments/set-experiment-tag" }
    let(:default_params) { { experiment_id: experiment.iid.to_s, key: 'some_key', value: 'value' } }
    let(:params) { default_params }
    let(:request) { post api(route), params: params, headers: headers }

    it 'logs the tag', :aggregate_failures do
      is_expected.to have_gitlab_http_status(:ok)
      expect(json_response).to be_empty
      expect(experiment.reload.metadata.map(&:name)).to include('some_key')
    end

    describe 'Error Cases' do
      context 'when tag was already set' do
        let(:params) { default_params.merge(key: experiment.metadata[0].name) }

        it_behaves_like 'MLflow|Bad Request'
      end

      it_behaves_like 'MLflow|shared error cases'
      it_behaves_like 'MLflow|Requires api scope'
      it_behaves_like 'MLflow|Bad Request on missing required', [:key, :value]
    end
  end
end
