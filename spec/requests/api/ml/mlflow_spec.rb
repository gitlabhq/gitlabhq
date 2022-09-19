# frozen_string_literal: true

require 'spec_helper'
require 'mime/types'

RSpec.describe API::Ml::Mlflow do
  include SessionHelpers
  include ApiHelpers
  include HttpBasicAuthHelpers

  let_it_be(:project) { create(:project, :private) }
  let_it_be(:developer) { create(:user).tap { |u| project.add_developer(u) } }
  let_it_be(:experiment) do
    create(:ml_experiments, user: project.creator, project: project)
  end

  let_it_be(:candidate) do
    create(:ml_candidates, user: experiment.user, start_time: 1234, experiment: experiment)
  end

  let_it_be(:another_candidate) do
    create(:ml_candidates,
           experiment: create(:ml_experiments, project: create(:project)))
  end

  let(:current_user) { developer }
  let(:ff_value) { true }
  let(:scopes) { %w[read_api api] }
  let(:headers) do
    { 'Authorization' => "Bearer #{create(:personal_access_token, scopes: scopes, user: current_user).token}" }
  end

  let(:params) { {} }
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
      let(:scopes) { %w[read_api] }

      it { expect(response).to have_gitlab_http_status(:forbidden) }
    end
  end

  shared_examples 'Requires read_api scope' do
    context 'when user has access but token has wrong scope' do
      let(:scopes) { %w[read_user] }

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
      let(:current_user) { create(:user) }

      it_behaves_like 'Not Found'
    end

    context 'when ff is disabled' do
      let(:ff_value) { false }

      it_behaves_like 'Not Found'
    end
  end

  describe 'GET /projects/:id/ml/mflow/api/2.0/mlflow/get' do
    let(:experiment_iid) { experiment.iid.to_s }
    let(:route) { "/projects/#{project.id}/ml/mflow/api/2.0/mlflow/experiments/get?experiment_id=#{experiment_iid}" }

    it 'returns the experiment' do
      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to match_response_schema('ml/get_experiment')
      expect(json_response).to include({
                                         'experiment' => {
                                           'experiment_id' => experiment_iid,
                                           'name' => experiment.name,
                                           'lifecycle_stage' => 'active',
                                           'artifact_location' => 'not_implemented'
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
          let(:route) { "/projects/#{project.id}/ml/mflow/api/2.0/mlflow/experiments/get" }

          it_behaves_like 'Not Found - Resource Does Not Exist'
        end
      end

      it_behaves_like 'shared error cases'
      it_behaves_like 'Requires read_api scope'
    end
  end

  describe 'GET /projects/:id/ml/mflow/api/2.0/mlflow/experiments/get-by-name' do
    let(:experiment_name) { experiment.name }
    let(:route) do
      "/projects/#{project.id}/ml/mflow/api/2.0/mlflow/experiments/get-by-name?experiment_name=#{experiment_name}"
    end

    it 'returns the experiment' do
      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to match_response_schema('ml/get_experiment')
      expect(json_response).to include({
                                         'experiment' => {
                                           'experiment_id' => experiment.iid.to_s,
                                           'name' => experiment_name,
                                           'lifecycle_stage' => 'active',
                                           'artifact_location' => 'not_implemented'
                                         }
                                       })
    end

    describe 'Error States' do
      context 'when has access but experiment does not exist' do
        let(:experiment_name) { "random_experiment" }

        it_behaves_like 'Not Found - Resource Does Not Exist'
      end

      context 'when has access but experiment_name is not passed' do
        let(:route) { "/projects/#{project.id}/ml/mflow/api/2.0/mlflow/experiments/get-by-name" }

        it_behaves_like 'Not Found - Resource Does Not Exist'
      end

      it_behaves_like 'shared error cases'
      it_behaves_like 'Requires read_api scope'
    end
  end

  describe 'POST /projects/:id/ml/mflow/api/2.0/mlflow/experiments/create' do
    let(:route) do
      "/projects/#{project.id}/ml/mflow/api/2.0/mlflow/experiments/create"
    end

    let(:params) { { name: 'new_experiment' } }
    let(:request) { post api(route), params: params, headers: headers }

    it 'creates the experiment' do
      expect(response).to have_gitlab_http_status(:created)
      expect(json_response).to include('experiment_id' )
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
        let(:route) { "/projects/#{non_existing_record_id}/ml/mflow/api/2.0/mlflow/experiments/create" }

        it_behaves_like 'Not Found', '404 Project Not Found'
      end

      it_behaves_like 'shared error cases'
      it_behaves_like 'Requires api scope'
    end
  end

  describe 'Runs' do
    describe 'POST /projects/:id/ml/mflow/api/2.0/mlflow/runs/create' do
      let(:route) do
        "/projects/#{project.id}/ml/mflow/api/2.0/mlflow/runs/create"
      end

      let(:params) { { experiment_id: experiment.iid.to_s, start_time: Time.now.to_i } }
      let(:request) { post api(route), params: params, headers: headers }

      it 'creates the run' do
        expected_properties = {
          'experiment_id' => params[:experiment_id],
          'user_id' => current_user.id.to_s,
          'start_time' => params[:start_time],
          'artifact_uri' => 'not_implemented',
          'status' => "RUNNING",
          'lifecycle_stage' => "active"
        }

        expect(response).to have_gitlab_http_status(:created)
        expect(response).to match_response_schema('ml/run')
        expect(json_response['run']).to include('info' => hash_including(**expected_properties), 'data' => {})
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

        it_behaves_like 'shared error cases'
        it_behaves_like 'Requires api scope'
      end
    end

    describe 'GET /projects/:id/ml/mflow/api/2.0/mlflow/runs/get' do
      let_it_be(:route) do
        "/projects/#{project.id}/ml/mflow/api/2.0/mlflow/runs/get"
      end

      let_it_be(:candidate) { create(:ml_candidates, user: experiment.user, start_time: 1234, experiment: experiment) }

      let(:params) { { 'run_id' => candidate.iid } }

      it 'gets the run' do
        expected_properties = {
          'experiment_id' => candidate.experiment.iid.to_s,
          'user_id' => candidate.user.id.to_s,
          'start_time' => candidate.start_time,
          'artifact_uri' => 'not_implemented',
          'status' => "RUNNING",
          'lifecycle_stage' => "active"
        }

        expect(response).to have_gitlab_http_status(:success)
        expect(response).to match_response_schema('ml/run')
        expect(json_response['run']).to include('info' => hash_including(**expected_properties), 'data' => {})
      end

      describe 'Error States' do
        context 'when run id is not passed' do
          let(:params) { {} }

          it_behaves_like 'Not Found - Resource Does Not Exist'
        end

        context 'when run id does not exist' do
          let(:params) { { run_id: non_existing_record_iid.to_s } }

          it_behaves_like 'Not Found - Resource Does Not Exist'
        end

        context 'when run id exists but does not belong to project' do
          let(:params) { { run_id: another_candidate.iid.to_s } }

          it_behaves_like 'Not Found - Resource Does Not Exist'
        end

        it_behaves_like 'shared error cases'
        it_behaves_like 'Requires read_api scope'
      end
    end
  end

  describe 'POST /projects/:id/ml/mflow/api/2.0/mlflow/runs/update' do
    let(:route) { "/projects/#{project.id}/ml/mflow/api/2.0/mlflow/runs/update" }
    let(:params) { { run_id: candidate.iid.to_s, status: 'FAILED', end_time: Time.now.to_i } }
    let(:request) { post api(route), params: params, headers: headers }

    it 'updates the run' do
      expected_properties = {
        'experiment_id' => candidate.experiment.iid.to_s,
        'user_id' => candidate.user.id.to_s,
        'start_time' => candidate.start_time,
        'end_time' => params[:end_time],
        'artifact_uri' => 'not_implemented',
        'status' => 'FAILED',
        'lifecycle_stage' => 'active'
      }

      expect(response).to have_gitlab_http_status(:success)
      expect(response).to match_response_schema('ml/update_run')
      expect(json_response).to include('run_info' => hash_including(**expected_properties))
    end

    describe 'Error States' do
      context 'when run id is not passed' do
        let(:params) { {} }

        it_behaves_like 'Not Found - Resource Does Not Exist'
      end

      context 'when run id does not exist' do
        let(:params) { { run_id: non_existing_record_iid.to_s } }

        it_behaves_like 'Not Found - Resource Does Not Exist'
      end

      context 'when run id exists but does not belong to project' do
        let(:params) { { run_id: another_candidate.iid.to_s } }

        it_behaves_like 'Not Found - Resource Does Not Exist'
      end

      context 'when run id exists but status in invalid' do
        let(:params) { { run_id: candidate.iid.to_s, status: 'YOLO', end_time: Time.now.to_i } }

        it_behaves_like 'Bad Request'
      end

      context 'when run id exists but end_time is invalid' do
        let(:params) { { run_id: candidate.iid.to_s, status: 'FAILED', end_time: 's' } }

        it_behaves_like 'Bad Request'
      end

      it_behaves_like 'shared error cases'
      it_behaves_like 'Requires api scope'
    end
  end
end
