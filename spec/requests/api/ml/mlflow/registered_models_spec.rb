# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Ml::Mlflow::RegisteredModels, feature_category: :mlops do
  let_it_be(:project) { create(:project) }
  let_it_be(:developer) { create(:user, developer_of: project) }
  let_it_be(:model) do
    create(:ml_models, :with_metadata, project: project)
  end

  let_it_be(:model_version) { create(:ml_model_versions, project: project, model: model, version: '1.0.0') }

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

  describe 'GET /projects/:id/ml/mlflow/api/2.0/mlflow/registered-models/get' do
    let(:model_name) { model.name }
    let(:route) { "/projects/#{project_id}/ml/mlflow/api/2.0/mlflow/registered-models/get?name=#{model_name}" }

    it 'returns the model', :aggregate_failures do
      is_expected.to have_gitlab_http_status(:ok)
      is_expected.to match_response_schema('ml/get_model')
    end

    describe 'Error States' do
      context 'when has access' do
        context 'and model does not exist' do
          let(:model_name) { 'foo' }

          it_behaves_like 'MLflow|Not Found - Resource Does Not Exist'
        end

        context 'and name is not passed' do
          let(:route) { "/projects/#{project_id}/ml/mlflow/api/2.0/mlflow/registered-models/get" }

          it_behaves_like 'MLflow|Not Found - Resource Does Not Exist'
        end
      end

      it_behaves_like 'MLflow|an authenticated resource'
      it_behaves_like 'MLflow|a read-only model registry resource'
    end
  end

  describe 'GET /projects/:id/ml/mlflow/api/2.0/mlflow/registered-models/alias' do
    let(:model_name) { model_version.model.name }
    let(:version) { model_version.version }
    let(:route) do
      "/projects/#{project_id}/ml/mlflow/api/2.0/mlflow/registered-models/alias?name=#{model_name}&alias=#{version}"
    end

    it 'returns the model version', :aggregate_failures do
      is_expected.to have_gitlab_http_status(:ok)

      expect(json_response['model_version']['name']).to eq(model_name)
      expect(json_response['model_version']['aliases']).to eq([version])
    end

    describe 'Error States' do
      context 'when has access' do
        context 'and model does not exist' do
          let(:model_name) { 'foo' }

          it_behaves_like 'MLflow|Not Found - Resource Does Not Exist'
        end

        context 'and model version does not exist' do
          let(:version) { '1.0.1' }

          it_behaves_like 'MLflow|Not Found - Resource Does Not Exist'
        end

        context 'and name is not passed' do
          let(:route) { "/projects/#{project_id}/ml/mlflow/api/2.0/mlflow/registered-models/alias" }

          it_behaves_like 'MLflow|Not Found - Resource Does Not Exist'
        end

        context 'and alias is not passed' do
          let(:route) { "/projects/#{project_id}/ml/mlflow/api/2.0/mlflow/registered-models/alias?name=#{model_name}" }

          it_behaves_like 'MLflow|Not Found - Resource Does Not Exist'
        end
      end

      it_behaves_like 'MLflow|an authenticated resource'
      it_behaves_like 'MLflow|a read-only model registry resource'
    end
  end

  describe 'POST /projects/:id/ml/mlflow/api/2.0/mlflow/registered-models/create' do
    let(:route) do
      "/projects/#{project_id}/ml/mlflow/api/2.0/mlflow/registered-models/create"
    end

    let(:params) { { name: 'my-model-name' } }
    let(:request) { post api(route), params: params, headers: headers }

    it 'creates the model', :aggregate_failures do
      is_expected.to have_gitlab_http_status(:ok)
      expect(json_response).to include('registered_model')
    end

    describe 'Error States' do
      context 'when the model name is not passed' do
        let(:params) { {} }

        it_behaves_like 'MLflow|an invalid request'
      end

      context 'when the model name already exists' do
        let(:existing_model) do
          create(:ml_models, user: current_user, project: project)
        end

        let(:params) { { name: existing_model.name } }

        it "is Bad Request", :aggregate_failures do
          is_expected.to have_gitlab_http_status(:bad_request)

          expect(json_response).to include({ 'error_code' => 'RESOURCE_ALREADY_EXISTS' })
        end
      end

      context 'when project does not exist' do
        let(:route) { "/projects/#{non_existing_record_id}/ml/mlflow/api/2.0/mlflow/registered-models/create" }

        it "is Not Found", :aggregate_failures do
          is_expected.to have_gitlab_http_status(:not_found)

          expect(json_response['message']).to eq('404 Project Not Found')
        end
      end

      # TODO: Ensure consisted error responses https://gitlab.com/gitlab-org/gitlab/-/issues/429731
      context 'when a duplicate tag name is supplied' do
        let(:params) do
          { name: 'my-model-name', tags: [{ key: 'key1', value: 'value1' }, { key: 'key1', value: 'value2' }] }
        end

        it "creates the model with only the second tag", :aggregate_failures do
          expect(json_response).to include({ 'error_code' => 'RESOURCE_ALREADY_EXISTS' })
        end
      end

      # TODO: Ensure consisted error responses https://gitlab.com/gitlab-org/gitlab/-/issues/429731
      context 'when an empty tag name is supplied' do
        let(:params) do
          { name: 'my-model-name', tags: [{ key: '', value: 'value1' }, { key: 'key1', value: 'value2' }] }
        end

        it "creates the model with only the second tag", :aggregate_failures do
          expect(json_response).to include({ 'error_code' => 'RESOURCE_ALREADY_EXISTS' })
        end
      end

      it_behaves_like 'MLflow|an authenticated resource'
      it_behaves_like 'MLflow|a read/write model registry resource'
    end
  end

  describe 'PATCH /projects/:id/ml/mlflow/api/2.0/mlflow/registered-models/update' do
    let(:model_name) { model.name }
    let(:model_description) { 'updated model description' }
    let(:params) { { name: model_name, description: model_description } }
    let(:route) { "/projects/#{project_id}/ml/mlflow/api/2.0/mlflow/registered-models/update" }
    let(:request) { patch api(route), params: params, headers: headers }

    it 'returns the updated model', :aggregate_failures do
      is_expected.to have_gitlab_http_status(:ok)
      is_expected.to match_response_schema('ml/update_model')
      expect(json_response["registered_model"]["description"]).to eq(model_description)
    end

    describe 'Error States' do
      context 'when has access' do
        context 'and model does not exist' do
          let(:model_name) { 'foo' }

          it_behaves_like 'MLflow|Not Found - Resource Does Not Exist'
        end

        context 'and name is not passed' do
          let(:params) { { description: model_description } }

          it_behaves_like 'MLflow|Not Found - Resource Does Not Exist'
        end
      end

      it_behaves_like 'MLflow|an authenticated resource'
      it_behaves_like 'MLflow|a read/write model registry resource'
    end
  end

  describe 'POST /projects/:id/ml/mlflow/api/2.0/mlflow/registered-models/get-latest-versions' do
    let_it_be(:version1) { create(:ml_model_versions, model: model, created_at: 1.week.ago) }
    let_it_be(:version2) { create(:ml_model_versions, model: model, created_at: 1.day.ago) }

    let(:model_name) { model.name }
    let(:params) { { name: model_name } }
    let(:route) { "/projects/#{project_id}/ml/mlflow/api/2.0/mlflow/registered-models/get-latest-versions" }
    let(:request) { post api(route), params: params, headers: headers }

    it 'returns an array with the most recently created model version', :aggregate_failures do
      is_expected.to have_gitlab_http_status(:ok)
      is_expected.to match_response_schema('ml/get_latest_versions')
      expect(json_response["model_versions"][0]["name"]).to eq(model_name)
      expect(json_response["model_versions"][0]["version"]).to eq(version2.id.to_s)
    end

    describe 'Error States' do
      context 'when has access' do
        context 'and model does not exist' do
          let(:model_name) { 'foo' }

          it_behaves_like 'MLflow|Not Found - Resource Does Not Exist'
        end

        context 'and name is not passed' do
          let(:params) { {} }

          it_behaves_like 'MLflow|Not Found - Resource Does Not Exist'
        end
      end

      it_behaves_like 'MLflow|an authenticated resource'
      it_behaves_like 'MLflow|a read-only model registry resource'
    end
  end

  describe 'DELETE /projects/:id/ml/mlflow/api/2.0/mlflow/registered-models/delete' do
    let(:model_name) { model.name }
    let(:params) { { name: model_name } }
    let(:route) { "/projects/#{project_id}/ml/mlflow/api/2.0/mlflow/registered-models/delete" }
    let(:request) { delete api(route), params: params, headers: headers }

    it 'returns a success response', :aggregate_failures do
      is_expected.to have_gitlab_http_status(:ok)
      expect(json_response).to eq({})
    end

    describe 'Error States' do
      context 'when destroy fails' do
        it 'returns an error' do
          allow(Ml::DestroyModelService).to receive_message_chain(:new,
            :execute).and_return(ServiceResponse.error(message: ""))

          is_expected.to have_gitlab_http_status(:bad_request)
          expect(json_response["message"]).to eq("Model could not be deleted")
        end
      end

      context 'when has access' do
        context 'and model does not exist' do
          let(:model_name) { 'foo' }

          it_behaves_like 'MLflow|Not Found - Resource Does Not Exist'
        end

        context 'and name is not passed' do
          let(:params) { {} }

          it_behaves_like 'MLflow|Not Found - Resource Does Not Exist'
        end
      end

      it_behaves_like 'MLflow|an authenticated resource'
      it_behaves_like 'MLflow|a read/write model registry resource'
    end
  end

  describe 'GET /projects/:id/ml/mlflow/api/2.0/mlflow/registered-models/search' do
    let_it_be(:model2) do
      create(:ml_models, :with_metadata, project: project)
    end

    let(:route) { "/projects/#{project_id}/ml/mlflow/api/2.0/mlflow/registered-models/search" }

    it 'returns all the models', :aggregate_failures do
      is_expected.to have_gitlab_http_status(:ok)
      is_expected.to match_response_schema('ml/list_models')
      expect(json_response["registered_models"].count).to be(2)
    end

    context "with a valid filter supplied" do
      let(:filter) { "name='#{model2.name}'" }
      let(:route) { "/projects/#{project_id}/ml/mlflow/api/2.0/mlflow/registered-models/search?filter=#{filter}" }

      it 'returns only the models for the given filter' do
        is_expected.to have_gitlab_http_status(:ok)
        expect(json_response["registered_models"].count).to be(1)
      end
    end

    context "with an invalid filter supplied" do
      let(:filter) { "description='foo'" }
      let(:route) { "/projects/#{project_id}/ml/mlflow/api/2.0/mlflow/registered-models/search?filter=#{filter}" }

      it 'returns an error' do
        is_expected.to have_gitlab_http_status(:bad_request)

        expect(json_response).to include({ 'error_code' => 'INVALID_PARAMETER_VALUE' })
      end
    end

    describe 'Error States' do
      it_behaves_like 'MLflow|an authenticated resource'
      it_behaves_like 'MLflow|a read-only model registry resource'
    end
  end
end
