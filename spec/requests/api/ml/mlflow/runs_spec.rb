# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Ml::Mlflow::Runs, feature_category: :mlops do
  let_it_be(:project) { create(:project) }
  let_it_be(:developer) { create(:user, developer_of: project) }
  let_it_be(:another_project) { build(:project).tap { |p| p.add_developer(developer) } }
  let_it_be(:experiment) do
    create(:ml_experiments, :with_metadata, project: project)
  end

  let_it_be(:candidate) do
    create(:ml_candidates,
      :with_metrics_and_params, :with_metadata,
      user: experiment.user, start_time: 1234, experiment: experiment, project: project)
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

  subject(:api_response) do
    request
    response
  end

  before do
    allow(Gitlab::Application.routes).to receive(:default_url_options)
      .and_return(protocol: 'http', host: 'www.example.com', script_name: '')
  end

  RSpec.shared_examples 'MLflow|run_id param error cases' do
    context 'when run id is not passed' do
      let(:params) { {} }

      it "is Bad Request" do
        is_expected.to have_gitlab_http_status(:bad_request)
      end
    end

    context 'when run_id is invalid' do
      let(:params) { default_params.merge(run_id: non_existing_record_iid.to_s) }

      it "is Resource Does Not Exist", :aggregate_failures do
        is_expected.to have_gitlab_http_status(:not_found)

        expect(json_response).to include({ "error_code" => 'RESOURCE_DOES_NOT_EXIST' })
      end
    end

    context 'when run_id is not in in the project' do
      let(:project_id) { another_project.id }

      it "is Resource Does Not Exist", :aggregate_failures do
        is_expected.to have_gitlab_http_status(:not_found)

        expect(json_response).to include({ "error_code" => 'RESOURCE_DOES_NOT_EXIST' })
      end
    end
  end

  describe 'POST /projects/:id/ml/mlflow/api/2.0/mlflow/runs/create' do
    let(:route) { "/projects/#{project_id}/ml/mlflow/api/2.0/mlflow/runs/create" }
    let(:params) do
      {
        experiment_id: experiment.iid.to_s,
        start_time: Time.now.to_i,
        run_name: "A new Run",
        tags: [
          { key: 'hello', value: 'world' }
        ]
      }
    end

    let(:request) { post api(route), params: params, headers: headers }

    it 'creates the run', :aggregate_failures do
      expected_properties = {
        'experiment_id' => params[:experiment_id],
        'user_id' => current_user.id.to_s,
        'run_name' => "A new Run",
        'start_time' => params[:start_time],
        'status' => 'RUNNING',
        'lifecycle_stage' => 'active'
      }

      is_expected.to have_gitlab_http_status(:ok)
      is_expected.to match_response_schema('ml/run')
      expect(json_response['run']).to include('info' => hash_including(**expected_properties),
        'data' => {
          'metrics' => [],
          'params' => [],
          'tags' => [{ 'key' => 'hello', 'value' => 'world' }]
        })
    end

    describe 'Error States' do
      context 'when experiment id is not passed' do
        let(:params) { {} }

        it_behaves_like 'MLflow|Bad Request'
      end

      context 'when experiment id does not exist' do
        let(:params) { { experiment_id: non_existing_record_iid.to_s } }

        it_behaves_like 'MLflow|Not Found - Resource Does Not Exist'
      end

      context 'when experiment exists but is not part of the project' do
        let(:project_id) { another_project.id }

        it_behaves_like 'MLflow|Not Found - Resource Does Not Exist'
      end

      it_behaves_like 'MLflow|shared error cases'
      it_behaves_like 'MLflow|Requires api scope and write permission'
    end
  end

  describe 'GET /projects/:id/ml/mlflow/api/2.0/mlflow/runs/get' do
    let(:route) { "/projects/#{project_id}/ml/mlflow/api/2.0/mlflow/runs/get" }
    let(:default_params) { { 'run_id' => candidate.eid } }

    it 'gets the run', :aggregate_failures do
      expected_properties = {
        'experiment_id' => candidate.experiment.iid.to_s,
        'user_id' => candidate.user.id.to_s,
        'start_time' => candidate.start_time,
        'artifact_uri' => "http://www.example.com/api/v4/projects/#{project_id}/packages/ml_models/candidate:#{candidate.iid}/files/",
        'status' => "RUNNING",
        'lifecycle_stage' => "active"
      }

      is_expected.to have_gitlab_http_status(:ok)
      is_expected.to match_response_schema('ml/run')
      expect(json_response['run']).to include(
        'info' => hash_including(**expected_properties),
        'data' => {
          'metrics' => [
            hash_including('key' => candidate.metrics[0].name),
            hash_including('key' => candidate.metrics[1].name)
          ],
          'params' => [
            { 'key' => candidate.params[0].name, 'value' => candidate.params[0].value },
            { 'key' => candidate.params[1].name, 'value' => candidate.params[1].value }
          ],
          'tags' => [
            { 'key' => candidate.metadata[0].name,  'value' => candidate.metadata[0].value },
            { 'key' => candidate.metadata[1].name,  'value' => candidate.metadata[1].value }
          ]
        })
    end

    context 'with a relative root URL' do
      before do
        allow(Gitlab::Application.routes).to receive(:default_url_options)
          .and_return(protocol: 'http', host: 'www.example.com', script_name: '/gitlab/root')
      end

      it 'gets a run including a valid artifact_uri' do
        expect(json_response['run']['info']['artifact_uri']).to eql("http://www.example.com/gitlab/root/api/v4/projects/#{project_id}/packages/ml_models/candidate:#{candidate.iid}/files/")
      end
    end

    describe 'Error States' do
      it_behaves_like 'MLflow|run_id param error cases'
      it_behaves_like 'MLflow|shared error cases'
      it_behaves_like 'MLflow|Requires read_api scope'
    end
  end

  describe 'POST /projects/:id/ml/mlflow/api/2.0/mlflow/runs/search' do
    let_it_be(:search_experiment) { create(:ml_experiments, user: nil, project: project) }
    let_it_be(:first_candidate) do
      create(:ml_candidates, experiment: search_experiment, name: 'c', user: nil).tap do |c|
        c.metrics.create!(name: 'metric1', value: 0.3)
      end
    end

    let_it_be(:second_candidate) do
      create(:ml_candidates, experiment: search_experiment, name: 'a', user: nil).tap do |c|
        c.metrics.create!(name: 'metric1', value: 0.2)
      end
    end

    let_it_be(:third_candidate) do
      create(:ml_candidates, experiment: search_experiment, name: 'b', user: nil).tap do |c|
        c.metrics.create!(name: 'metric1', value: 0.6)
      end
    end

    let(:route) { "/projects/#{project_id}/ml/mlflow/api/2.0/mlflow/runs/search" }
    let(:order_by) { nil }
    let(:default_params) do
      {
        'max_results' => 2,
        'experiment_ids' => [search_experiment.iid],
        'order_by' => order_by
      }
    end

    let(:request) { post api(route), params: params, headers: headers }

    it 'searches runs for a project', :aggregate_failures do
      is_expected.to have_gitlab_http_status(:ok)
      is_expected.to match_response_schema('ml/search_runs')
    end

    describe 'pagination and ordering' do
      RSpec.shared_examples 'a paginated search runs request with order' do
        it 'paginates respecting the provided order by' do
          first_page_runs = json_response['runs']
          expect(first_page_runs.size).to eq(2)

          expect(first_page_runs[0]['info']['run_id']).to eq(expected_order[0].eid)
          expect(first_page_runs[1]['info']['run_id']).to eq(expected_order[1].eid)

          params = default_params.merge(page_token: json_response['next_page_token'])

          post api(route), params: params, headers: headers

          second_page_response = Gitlab::Json.parse(response.body)
          second_page_runs = second_page_response['runs']

          expect(second_page_response['next_page_token']).to be_nil
          expect(second_page_runs.size).to eq(1)
          expect(second_page_runs[0]['info']['run_id']).to eq(expected_order[2].eid)
        end
      end

      let(:default_order) { [third_candidate, second_candidate, first_candidate] }

      context 'when ordering is not provided' do
        let(:expected_order) { default_order }

        it_behaves_like 'a paginated search runs request with order'
      end

      context 'when order by column is provided', 'and column exists' do
        let(:order_by) { 'name ASC'  }
        let(:expected_order) { [second_candidate, third_candidate, first_candidate] }

        it_behaves_like 'a paginated search runs request with order'
      end

      context 'when order by column is provided', 'and column does not exist' do
        let(:order_by) { 'something DESC' }
        let(:expected_order) { default_order }

        it_behaves_like 'a paginated search runs request with order'
      end

      context 'when order by metric is provided', 'and metric exists' do
        let(:order_by) { 'metrics.metric1' }
        let(:expected_order) { [third_candidate, first_candidate, second_candidate] }

        it_behaves_like 'a paginated search runs request with order'
      end

      context 'when order by metric is provided', 'and metric does not exist' do
        let(:order_by) { 'metrics.something' }

        it 'returns no results' do
          expect(json_response['runs']).to be_empty
        end
      end

      context 'when order by params is provided' do
        let(:order_by) { 'params.something'  }
        let(:expected_order) { default_order }

        it_behaves_like 'a paginated search runs request with order'
      end
    end

    describe 'Error States' do
      context 'when experiment_ids is not passed' do
        let(:default_params) { {} }

        it_behaves_like 'MLflow|Bad Request'
      end

      context 'when experiment_ids is empty' do
        let(:default_params) { { 'experiment_ids' => [] } }

        it_behaves_like 'MLflow|Not Found - Resource Does Not Exist'
      end

      context 'when experiment_ids is invalid' do
        let(:default_params) { { 'experiment_ids' => [non_existing_record_id] } }

        it_behaves_like 'MLflow|Not Found - Resource Does Not Exist'
      end

      it_behaves_like 'MLflow|shared error cases'
      it_behaves_like 'MLflow|Requires read_api scope'
    end
  end

  describe 'POST /projects/:id/ml/mlflow/api/2.0/mlflow/runs/update' do
    let(:default_params) { { run_id: candidate.eid.to_s, status: 'FAILED', end_time: Time.now.to_i } }
    let(:request) { post api(route), params: params, headers: headers }
    let(:route) { "/projects/#{project_id}/ml/mlflow/api/2.0/mlflow/runs/update" }

    it 'updates the run', :aggregate_failures do
      expected_properties = {
        'experiment_id' => candidate.experiment.iid.to_s,
        'user_id' => candidate.user.id.to_s,
        'start_time' => candidate.start_time,
        'end_time' => params[:end_time],
        'artifact_uri' => "http://www.example.com/api/v4/projects/#{project_id}/packages/ml_models/candidate:#{candidate.iid}/files/",
        'status' => 'FAILED',
        'lifecycle_stage' => 'active'
      }

      is_expected.to have_gitlab_http_status(:ok)
      is_expected.to match_response_schema('ml/update_run')
      expect(json_response).to include('run_info' => hash_including(**expected_properties))
    end

    describe 'Error States' do
      context 'when status in invalid' do
        let(:params) { default_params.merge(status: 'YOLO') }

        it_behaves_like 'MLflow|Bad Request'
      end

      context 'when end_time is invalid' do
        let(:params) { default_params.merge(end_time: 's') }

        it_behaves_like 'MLflow|Bad Request'
      end

      it_behaves_like 'MLflow|shared error cases'
      it_behaves_like 'MLflow|Requires api scope and write permission'
      it_behaves_like 'MLflow|run_id param error cases'
    end
  end

  describe 'POST /projects/:id/ml/mlflow/api/2.0/mlflow/runs/log-metric' do
    let(:route) { "/projects/#{project_id}/ml/mlflow/api/2.0/mlflow/runs/log-metric" }
    let(:default_params) { { run_id: candidate.eid.to_s, key: 'some_key', value: 10.0, timestamp: Time.now.to_i } }
    let(:request) { post api(route), params: params, headers: headers }

    it 'logs the metric', :aggregate_failures do
      is_expected.to have_gitlab_http_status(:ok)
      expect(json_response).to be_empty
      expect(candidate.metrics.reload.length).to eq(3)
    end

    describe 'Error Cases' do
      it_behaves_like 'MLflow|shared error cases'
      it_behaves_like 'MLflow|Requires api scope and write permission'
      it_behaves_like 'MLflow|run_id param error cases'
      it_behaves_like 'MLflow|Bad Request on missing required', [:key, :value, :timestamp]
    end
  end

  describe 'POST /projects/:id/ml/mlflow/api/2.0/mlflow/runs/log-parameter' do
    let(:route) { "/projects/#{project_id}/ml/mlflow/api/2.0/mlflow/runs/log-parameter" }
    let(:default_params) { { run_id: candidate.eid.to_s, key: 'some_key', value: 'value' } }
    let(:request) { post api(route), params: params, headers: headers }

    it 'logs the parameter', :aggregate_failures do
      is_expected.to have_gitlab_http_status(:ok)
      expect(json_response).to be_empty
      expect(candidate.params.reload.length).to eq(3)
    end

    describe 'Error Cases' do
      context 'when parameter was already logged' do
        let(:params) { default_params.tap { |p| p[:key] = candidate.params[0].name } }

        it_behaves_like 'MLflow|Bad Request'
      end

      it_behaves_like 'MLflow|shared error cases'
      it_behaves_like 'MLflow|Requires api scope and write permission'
      it_behaves_like 'MLflow|run_id param error cases'
      it_behaves_like 'MLflow|Bad Request on missing required', [:key, :value]
    end
  end

  describe 'POST /projects/:id/ml/mlflow/api/2.0/mlflow/runs/set-tag' do
    let(:route) { "/projects/#{project_id}/ml/mlflow/api/2.0/mlflow/runs/set-tag" }
    let(:default_params) { { run_id: candidate.eid.to_s, key: 'some_key', value: 'value' } }
    let(:request) { post api(route), params: params, headers: headers }

    it 'logs the tag', :aggregate_failures do
      is_expected.to have_gitlab_http_status(:ok)
      expect(json_response).to be_empty
      expect(candidate.reload.metadata.map(&:name)).to include('some_key')
    end

    describe 'Error Cases' do
      context 'when tag was already logged' do
        let(:params) { default_params.tap { |p| p[:key] = candidate.metadata[0].name } }

        it_behaves_like 'MLflow|Bad Request'
      end

      it_behaves_like 'MLflow|shared error cases'
      it_behaves_like 'MLflow|Requires api scope and write permission'
      it_behaves_like 'MLflow|run_id param error cases'
      it_behaves_like 'MLflow|Bad Request on missing required', [:key, :value]
    end
  end

  describe 'POST /projects/:id/ml/mlflow/api/2.0/mlflow/runs/log-batch' do
    let_it_be(:candidate2) do
      create(:ml_candidates, user: experiment.user, start_time: 1234, experiment: experiment, project: project)
    end

    let(:route) { "/projects/#{project_id}/ml/mlflow/api/2.0/mlflow/runs/log-batch" }
    let(:default_params) do
      {
        run_id: candidate2.eid.to_s,
        metrics: [
          { key: 'mae', value: 2.5, timestamp: 1552550804 },
          { key: 'rmse', value: 2.7, timestamp: 1552550804 }
        ],
        params: [{ key: 'model_class', value: 'LogisticRegression' }],
        tags: [{ key: 'tag1', value: 'tag.value.1' }]
      }
    end

    let(:request) { post api(route), params: params, headers: headers }

    it 'logs parameters and metrics', :aggregate_failures do
      is_expected.to have_gitlab_http_status(:ok)
      expect(json_response).to be_empty
      expect(candidate2.params.size).to eq(1)
      expect(candidate2.metadata.size).to eq(1)
      expect(candidate2.metrics.size).to eq(2)
    end

    context 'when parameter was already logged' do
      let(:params) do
        default_params.tap { |p| p[:params] = [{ key: 'hello', value: 'a' }, { key: 'hello', value: 'b' }] }
      end

      it 'does not log', :aggregate_failures do
        is_expected.to have_gitlab_http_status(:ok)
        expect(candidate2.params.reload.size).to eq(1)
      end
    end

    context 'when tag was already logged' do
      let(:params) do
        default_params.tap { |p| p[:tags] = [{ key: 'tag1', value: 'a' }, { key: 'tag1', value: 'b' }] }
      end

      it 'logs only 1', :aggregate_failures do
        is_expected.to have_gitlab_http_status(:ok)
        expect(candidate2.metadata.reload.size).to eq(1)
      end
    end

    describe 'Error Cases' do
      context 'when required metric key is missing' do
        let(:params) { default_params.tap { |p| p[:metrics] = [p[:metrics][0].delete(:key)] } }

        it_behaves_like 'MLflow|Bad Request'
      end

      context 'when required param key is missing' do
        let(:params) { default_params.tap { |p| p[:params] = [p[:params][0].delete(:key)] } }

        it_behaves_like 'MLflow|Bad Request'
      end

      it_behaves_like 'MLflow|shared error cases'
      it_behaves_like 'MLflow|Requires api scope and write permission'
      it_behaves_like 'MLflow|run_id param error cases'
    end
  end

  describe 'POST /projects/:id/ml/mlflow/api/2.0/mlflow/runs/delete' do
    let(:route) { "/projects/#{project_id}/ml/mlflow/api/2.0/mlflow/runs/delete" }
    let(:default_params) { { run_id: candidate.eid.to_s } }
    let(:params) { default_params }
    let(:request) { post api(route), params: params, headers: headers }

    it 'deletes the run', :aggregate_failures do
      is_expected.to have_gitlab_http_status(:ok)
      expect { candidate.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end

    describe 'Error States' do
      context 'when run does not exist' do
        let(:params) { default_params.merge(run_id: non_existing_record_iid.to_s) }

        it_behaves_like 'MLflow|Not Found - Resource Does Not Exist'
      end

      context 'when run_id is not passed' do
        let(:params) { {} }

        it_behaves_like 'MLflow|Bad Request'
      end

      context 'when run has a model version associated' do
        let(:model) { create(:ml_models, project: project, name: "abc") }
        let(:model_version) { create(:ml_model_versions, project: project, model: model) }
        let(:params) { default_params.merge(run_id: model_version.candidate.eid.to_s) }

        it 'does not delete the candidate' do
          expect(json_response).to include({ "message" => 'Cannot delete a candidate associated to a model version' })
          expect(model_version.candidate.reload).to be_present
        end
      end

      it_behaves_like 'MLflow|shared error cases'
      it_behaves_like 'MLflow|Requires api scope and write permission'
    end
  end
end
