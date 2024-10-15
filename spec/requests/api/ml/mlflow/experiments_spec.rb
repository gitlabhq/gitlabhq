# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Ml::Mlflow::Experiments, feature_category: :mlops do
  let_it_be(:project) { create(:project) }
  let_it_be(:developer) { create(:user, developer_of: project) }
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
      it_behaves_like 'MLflow|Requires api scope and write permission'
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
      it_behaves_like 'MLflow|Requires api scope and write permission'
      it_behaves_like 'MLflow|Bad Request on missing required', [:key, :value]
    end
  end

  describe 'GET /projects/:id/ml/mlflow/api/2.0/mlflow/experiments/search' do
    let_it_be(:experiment_b) do
      create(:ml_experiments, project: project, name: "#{experiment.name}_2")
    end

    let_it_be(:experiment_c) do
      create(:ml_experiments, project: project, name: "#{experiment.name}_1")
    end

    let(:order_by) { nil }
    let(:default_params) do
      {
        'max_results' => 2,
        'order_by' => order_by
      }
    end

    let(:route) { "/projects/#{project_id}/ml/mlflow/api/2.0/mlflow/experiments/search" }
    let(:request) { post api(route), params: default_params.merge(**params), headers: headers }

    it 'returns all the models', :aggregate_failures do
      is_expected.to have_gitlab_http_status(:ok)
      is_expected.to match_response_schema('ml/search_experiments')
      expect(json_response["experiments"].count).to be(2)
    end

    describe 'pagination and ordering' do
      RSpec.shared_examples 'a paginated search experiments request with order' do
        it 'paginates respecting the provided order by' do
          first_page_experiments = json_response['experiments']
          expect(first_page_experiments.size).to eq(2)

          expect(first_page_experiments[0]['experiment_id'].to_i).to eq(expected_order[0].iid)
          expect(first_page_experiments[1]['experiment_id'].to_i).to eq(expected_order[1].iid)

          params = default_params.merge(page_token: json_response['next_page_token'])

          post api(route), params: params, headers: headers

          second_page_response = Gitlab::Json.parse(response.body)
          second_page_experiments = second_page_response['experiments']

          expect(second_page_response['next_page_token']).to be_nil
          expect(second_page_experiments.size).to eq(1)
          expect(second_page_experiments[0]['experiment_id'].to_i).to eq(expected_order[2].iid)
        end
      end

      let(:default_order) { [experiment_c, experiment_b, experiment] }

      context 'when ordering is not provided' do
        let(:expected_order) { default_order }

        it_behaves_like 'a paginated search experiments request with order'
      end

      context 'when order by column is provided', 'and column exists' do
        let(:order_by) { 'name ASC'  }
        let(:expected_order) { [experiment, experiment_c, experiment_b] }

        it_behaves_like 'a paginated search experiments request with order'
      end

      context 'when order by column is provided', 'and column does not exist' do
        let(:order_by) { 'something DESC' }
        let(:expected_order) { default_order }

        it_behaves_like 'a paginated search experiments request with order'
      end
    end

    describe 'Error States' do
      it_behaves_like 'MLflow|shared error cases'
      it_behaves_like 'MLflow|Requires api scope and write permission'
    end
  end

  describe 'POST /projects/:id/ml/mlflow/api/2.0/mlflow/experiments/delete' do
    let(:route) { "/projects/#{project_id}/ml/mlflow/api/2.0/mlflow/experiments/delete" }
    let(:default_params) { { experiment_id: experiment.iid.to_s } }
    let(:params) { default_params }
    let(:request) { post api(route), params: params, headers: headers }

    it 'deletes the experiment', :aggregate_failures do
      is_expected.to have_gitlab_http_status(:ok)
      expect { experiment.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end

    describe 'Error States' do
      context 'when experiment does not exist' do
        let(:params) { default_params.merge(experiment_id: non_existing_record_iid.to_s) }

        it_behaves_like 'MLflow|Not Found - Resource Does Not Exist'
      end

      context 'when experiment has a model_id' do
        let(:model) { create(:ml_models, project: project) }
        let(:experiment) { create(:ml_experiments, :with_metadata, project: project, model_id: model.id) }

        it 'returns an error' do
          is_expected.to have_gitlab_http_status(:bad_request)
          expect(json_response).to include({ 'message' => 'Cannot delete an experiment associated to a model' })
        end

        it_behaves_like 'MLflow|Bad Request'
      end

      context 'when experiment_id is not passed' do
        let(:params) { {} }

        it_behaves_like 'MLflow|Bad Request'
      end

      it_behaves_like 'MLflow|shared error cases'
      it_behaves_like 'MLflow|Requires api scope and write permission'
    end
  end
end
