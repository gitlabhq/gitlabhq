# frozen_string_literal: true

require 'spec_helper'
require 'mime/types'

RSpec.describe API::Ml::Mlflow, feature_category: :mlops do
  include SessionHelpers
  include ApiHelpers
  include HttpBasicAuthHelpers

  let_it_be(:project) { create(:project, :private) }
  let_it_be(:developer) { create(:user).tap { |u| project.add_developer(u) } }
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
  let(:ff_value) { true }
  let(:access_token) { tokens[:write] }
  let(:headers) do
    { 'Authorization' => "Bearer #{access_token.token}" }
  end

  let(:project_id) { project.id }
  let(:default_params) { {} }
  let(:params) { default_params }
  let(:request) { get api(route), params: params, headers: headers }

  before do
    stub_feature_flags(ml_experiment_tracking: ff_value)

    request
  end

  shared_examples 'Not Found' do |message|
    it "is Not Found" do
      expect(response).to have_gitlab_http_status(:not_found)

      expect(json_response['message']).to eq(message) if message.present?
    end
  end

  shared_examples 'Not Found - Resource Does Not Exist' do
    it "is Resource Does Not Exist" do
      expect(response).to have_gitlab_http_status(:not_found)

      expect(json_response).to include({ "error_code" => 'RESOURCE_DOES_NOT_EXIST' })
    end
  end

  shared_examples 'Requires api scope' do
    context 'when user has access but token has wrong scope' do
      let(:access_token) { tokens[:read] }

      it { expect(response).to have_gitlab_http_status(:forbidden) }
    end
  end

  shared_examples 'Requires read_api scope' do
    context 'when user has access but token has wrong scope' do
      let(:access_token) { tokens[:no_access] }

      it { expect(response).to have_gitlab_http_status(:forbidden) }
    end
  end

  shared_examples 'Bad Request' do |error_code = nil|
    it "is Bad Request" do
      expect(response).to have_gitlab_http_status(:bad_request)

      expect(json_response).to include({ 'error_code' => error_code }) if error_code.present?
    end
  end

  shared_examples 'shared error cases' do
    context 'when not authenticated' do
      let(:headers) { {} }

      it "is Unauthorized" do
        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context 'when user does not have access' do
      let(:access_token) { tokens[:different_user] }

      it_behaves_like 'Not Found'
    end

    context 'when ff is disabled' do
      let(:ff_value) { false }

      it_behaves_like 'Not Found'
    end
  end

  shared_examples 'run_id param error cases' do
    context 'when run id is not passed' do
      let(:params) { {} }

      it_behaves_like 'Bad Request'
    end

    context 'when run_id is invalid' do
      let(:params) { default_params.merge(run_id: non_existing_record_iid.to_s) }

      it_behaves_like 'Not Found - Resource Does Not Exist'
    end

    context 'when run_id is not in in the project' do
      let(:project_id) { another_project.id }

      it_behaves_like 'Not Found - Resource Does Not Exist'
    end
  end

  shared_examples 'Bad Request on missing required' do |keys|
    keys.each do |key|
      context "when \"#{key}\" is missing" do
        let(:params) { default_params.tap { |p| p.delete(key) } }

        it_behaves_like 'Bad Request'
      end
    end
  end

  describe 'GET /projects/:id/ml/mlflow/api/2.0/mlflow/experiments/get' do
    let(:experiment_iid) { experiment.iid.to_s }
    let(:route) { "/projects/#{project_id}/ml/mlflow/api/2.0/mlflow/experiments/get?experiment_id=#{experiment_iid}" }

    it 'returns the experiment', :aggregate_failures do
      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to match_response_schema('ml/get_experiment')
      expect(json_response).to include({
                                         'experiment' => {
                                           'experiment_id' => experiment_iid,
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
                                       })
    end

    describe 'Error States' do
      context 'when has access' do
        context 'and experiment does not exist' do
          let(:experiment_iid) { non_existing_record_iid.to_s }

          it_behaves_like 'Not Found - Resource Does Not Exist'
        end

        context 'and experiment_id is not passed' do
          let(:route) { "/projects/#{project_id}/ml/mlflow/api/2.0/mlflow/experiments/get" }

          it_behaves_like 'Not Found - Resource Does Not Exist'
        end
      end

      it_behaves_like 'shared error cases'
      it_behaves_like 'Requires read_api scope'
    end
  end

  describe 'GET /projects/:id/ml/mlflow/api/2.0/mlflow/experiments/list' do
    let(:route) { "/projects/#{project_id}/ml/mlflow/api/2.0/mlflow/experiments/list" }

    it 'returns the experiments' do
      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to match_response_schema('ml/list_experiments')
      expect(json_response).to include({
                                         'experiments' => [
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
                                         ]
                                       })
    end

    context 'when there are no experiments' do
      let(:project_id) { another_project.id }

      it 'returns an empty list' do
        expect(json_response).to include({ 'experiments' => [] })
      end
    end

    describe 'Error States' do
      it_behaves_like 'shared error cases'
      it_behaves_like 'Requires read_api scope'
    end
  end

  describe 'GET /projects/:id/ml/mlflow/api/2.0/mlflow/experiments/get-by-name' do
    let(:experiment_name) { experiment.name }
    let(:route) do
      "/projects/#{project_id}/ml/mlflow/api/2.0/mlflow/experiments/get-by-name?experiment_name=#{experiment_name}"
    end

    it 'returns the experiment', :aggregate_failures do
      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to match_response_schema('ml/get_experiment')
      expect(json_response).to include({
                                         'experiment' => {
                                           'experiment_id' => experiment.iid.to_s,
                                           'name' => experiment_name,
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
                                       })
    end

    describe 'Error States' do
      context 'when has access but experiment does not exist' do
        let(:experiment_name) { "random_experiment" }

        it_behaves_like 'Not Found - Resource Does Not Exist'
      end

      context 'when has access but experiment_name is not passed' do
        let(:route) { "/projects/#{project_id}/ml/mlflow/api/2.0/mlflow/experiments/get-by-name" }

        it_behaves_like 'Not Found - Resource Does Not Exist'
      end

      it_behaves_like 'shared error cases'
      it_behaves_like 'Requires read_api scope'
    end
  end

  describe 'POST /projects/:id/ml/mlflow/api/2.0/mlflow/experiments/create' do
    let(:route) do
      "/projects/#{project_id}/ml/mlflow/api/2.0/mlflow/experiments/create"
    end

    let(:params) { { name: 'new_experiment' } }
    let(:request) { post api(route), params: params, headers: headers }

    it 'creates the experiment', :aggregate_failures do
      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response).to include('experiment_id')
    end

    describe 'Error States' do
      context 'when experiment name is not passed' do
        let(:params) { {} }

        it_behaves_like 'Bad Request'
      end

      context 'when experiment name already exists' do
        let(:existing_experiment) do
          create(:ml_experiments, user: current_user, project: project)
        end

        let(:params) { { name: existing_experiment.name } }

        it_behaves_like 'Bad Request', 'RESOURCE_ALREADY_EXISTS'
      end

      context 'when project does not exist' do
        let(:route) { "/projects/#{non_existing_record_id}/ml/mlflow/api/2.0/mlflow/experiments/create" }

        it_behaves_like 'Not Found', '404 Project Not Found'
      end

      it_behaves_like 'shared error cases'
      it_behaves_like 'Requires api scope'
    end
  end

  describe 'POST /projects/:id/ml/mlflow/api/2.0/mlflow/experiments/set-experiment-tag' do
    let(:route) { "/projects/#{project_id}/ml/mlflow/api/2.0/mlflow/experiments/set-experiment-tag" }
    let(:default_params) { { experiment_id: experiment.iid.to_s, key: 'some_key', value: 'value' } }
    let(:params) { default_params }
    let(:request) { post api(route), params: params, headers: headers }

    it 'logs the tag', :aggregate_failures do
      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response).to be_empty
      expect(experiment.reload.metadata.map(&:name)).to include('some_key')
    end

    describe 'Error Cases' do
      context 'when tag was already set' do
        let(:params) { default_params.merge(key: experiment.metadata[0].name) }

        it_behaves_like 'Bad Request'
      end

      it_behaves_like 'shared error cases'
      it_behaves_like 'Requires api scope'
      it_behaves_like 'Bad Request on missing required', [:key, :value]
    end
  end

  describe 'Runs' do
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

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to match_response_schema('ml/run')
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

          it_behaves_like 'Bad Request'
        end

        context 'when experiment id does not exist' do
          let(:params) { { experiment_id: non_existing_record_iid.to_s } }

          it_behaves_like 'Not Found - Resource Does Not Exist'
        end

        context 'when experiment exists but is not part of the project' do
          let(:project_id) { another_project.id }

          it_behaves_like 'Not Found - Resource Does Not Exist'
        end

        it_behaves_like 'shared error cases'
        it_behaves_like 'Requires api scope'
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
          'artifact_uri' => "http://www.example.com/api/v4/projects/#{project_id}/packages/generic/ml_experiment_#{experiment.iid}/#{candidate.iid}/",
          'status' => "RUNNING",
          'lifecycle_stage' => "active"
        }

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to match_response_schema('ml/run')
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

      describe 'Error States' do
        it_behaves_like 'run_id param error cases'
        it_behaves_like 'shared error cases'
        it_behaves_like 'Requires read_api scope'
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
          'artifact_uri' => "http://www.example.com/api/v4/projects/#{project_id}/packages/generic/ml_experiment_#{experiment.iid}/#{candidate.iid}/",
          'status' => 'FAILED',
          'lifecycle_stage' => 'active'
        }

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to match_response_schema('ml/update_run')
        expect(json_response).to include('run_info' => hash_including(**expected_properties))
      end

      describe 'Error States' do
        context 'when status in invalid' do
          let(:params) { default_params.merge(status: 'YOLO') }

          it_behaves_like 'Bad Request'
        end

        context 'when end_time is invalid' do
          let(:params) { default_params.merge(end_time: 's') }

          it_behaves_like 'Bad Request'
        end

        it_behaves_like 'shared error cases'
        it_behaves_like 'Requires api scope'
        it_behaves_like 'run_id param error cases'
      end
    end

    describe 'POST /projects/:id/ml/mlflow/api/2.0/mlflow/runs/log-metric' do
      let(:route) { "/projects/#{project_id}/ml/mlflow/api/2.0/mlflow/runs/log-metric" }
      let(:default_params) { { run_id: candidate.eid.to_s, key: 'some_key', value: 10.0, timestamp: Time.now.to_i } }
      let(:request) { post api(route), params: params, headers: headers }

      it 'logs the metric', :aggregate_failures do
        candidate.metrics.reload

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to be_empty
        expect(candidate.metrics.length).to eq(3)
      end

      describe 'Error Cases' do
        it_behaves_like 'shared error cases'
        it_behaves_like 'Requires api scope'
        it_behaves_like 'run_id param error cases'
        it_behaves_like 'Bad Request on missing required', [:key, :value, :timestamp]
      end
    end

    describe 'POST /projects/:id/ml/mlflow/api/2.0/mlflow/runs/log-parameter' do
      let(:route) { "/projects/#{project_id}/ml/mlflow/api/2.0/mlflow/runs/log-parameter" }
      let(:default_params) { { run_id: candidate.eid.to_s, key: 'some_key', value: 'value' } }
      let(:request) { post api(route), params: params, headers: headers }

      it 'logs the parameter', :aggregate_failures do
        candidate.params.reload

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to be_empty
        expect(candidate.params.length).to eq(3)
      end

      describe 'Error Cases' do
        context 'when parameter was already logged' do
          let(:params) { default_params.tap { |p| p[:key] = candidate.params[0].name } }

          it_behaves_like 'Bad Request'
        end

        it_behaves_like 'shared error cases'
        it_behaves_like 'Requires api scope'
        it_behaves_like 'run_id param error cases'
        it_behaves_like 'Bad Request on missing required', [:key, :value]
      end
    end

    describe 'POST /projects/:id/ml/mlflow/api/2.0/mlflow/runs/set-tag' do
      let(:route) { "/projects/#{project_id}/ml/mlflow/api/2.0/mlflow/runs/set-tag" }
      let(:default_params) { { run_id: candidate.eid.to_s, key: 'some_key', value: 'value' } }
      let(:request) { post api(route), params: params, headers: headers }

      it 'logs the tag', :aggregate_failures do
        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to be_empty
        expect(candidate.reload.metadata.map(&:name)).to include('some_key')
      end

      describe 'Error Cases' do
        context 'when tag was already logged' do
          let(:params) { default_params.tap { |p| p[:key] = candidate.metadata[0].name } }

          it_behaves_like 'Bad Request'
        end

        it_behaves_like 'shared error cases'
        it_behaves_like 'Requires api scope'
        it_behaves_like 'run_id param error cases'
        it_behaves_like 'Bad Request on missing required', [:key, :value]
      end
    end

    describe 'POST /projects/:id/ml/mlflow/api/2.0/mlflow/runs/log-batch' do
      let(:candidate2) do
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
        expect(response).to have_gitlab_http_status(:ok)
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
          candidate.params.reload

          expect(response).to have_gitlab_http_status(:ok)
          expect(candidate2.params.size).to eq(1)
        end
      end

      context 'when tag was already logged' do
        let(:params) do
          default_params.tap { |p| p[:tags] = [{ key: 'tag1', value: 'a' }, { key: 'tag1', value: 'b' }] }
        end

        it 'logs only 1', :aggregate_failures do
          candidate.metadata.reload

          expect(response).to have_gitlab_http_status(:ok)
          expect(candidate2.metadata.size).to eq(1)
        end
      end

      describe 'Error Cases' do
        context 'when required metric key is missing' do
          let(:params) { default_params.tap { |p| p[:metrics] = [p[:metrics][0].delete(:key)] } }

          it_behaves_like 'Bad Request'
        end

        context 'when required param key is missing' do
          let(:params) { default_params.tap { |p| p[:params] = [p[:params][0].delete(:key)] } }

          it_behaves_like 'Bad Request'
        end

        it_behaves_like 'shared error cases'
        it_behaves_like 'Requires api scope'
        it_behaves_like 'run_id param error cases'
      end
    end
  end
end
