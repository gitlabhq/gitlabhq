# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Ml::Mlflow::ModelVersions, feature_category: :mlops do
  let_it_be(:project) { create(:project) }
  let_it_be(:developer) { create(:user, developer_of: project) }
  let_it_be(:another_project) { build(:project).tap { |p| p.add_developer(developer) } }

  let_it_be(:name) { 'a-model-name' }
  let_it_be(:version) { '0.0.1' }
  let_it_be(:model) { create(:ml_models, project: project, name: name) }
  let_it_be(:model_version) { create(:ml_model_versions, project: project, model: model, version: version) }

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

  describe 'GET /projects/:id/ml/mlflow/api/2.0/mlflow/model-versions/get' do
    let(:route) do
      "/projects/#{project_id}/ml/mlflow/api/2.0/mlflow/model-versions/get?name=#{name}&version=#{version}"
    end

    it 'returns the model version', :aggregate_failures do
      is_expected.to have_gitlab_http_status(:ok)
      expect(json_response['model_version']).not_to be_nil
      expect(json_response['model_version']['name']).to eq(name)
      expect(json_response['model_version']['version']).to eq(model_version.id.to_s)
    end

    describe 'Error States' do
      context 'when has access' do
        context 'and model name in incorrect' do
          let(:route) do
            "/projects/#{project_id}/ml/mlflow/api/2.0/mlflow/model-versions/get?name=--&version=#{version}"
          end

          it_behaves_like 'MLflow|Not Found - Resource Does Not Exist'
        end

        context 'and version in incorrect' do
          let(:route) do
            "/projects/#{project_id}/ml/mlflow/api/2.0/mlflow/model-versions/get?name=#{name}&version=--"
          end

          it_behaves_like 'MLflow|Not Found - Resource Does Not Exist'
        end

        context 'when user lacks read_model_registry rights' do
          before do
            allow(Ability).to receive(:allowed?).and_call_original
            allow(Ability).to receive(:allowed?)
                                .with(current_user, :read_model_registry, project)
                                .and_return(false)
          end

          it "is Not Found" do
            is_expected.to have_gitlab_http_status(:not_found)
          end
        end
      end

      it_behaves_like 'MLflow|an authenticated resource'
      it_behaves_like 'MLflow|a read-only model registry resource'
    end
  end

  describe 'UPDATE /projects/:id/ml/mlflow/api/2.0/mlflow/model-versions/update' do
    let(:params) { { name: name, version: version, description: 'description-text' } }
    let(:request) { patch api(route), params: params, headers: headers }

    let(:route) do
      "/projects/#{project_id}/ml/mlflow/api/2.0/mlflow/model-versions/update"
    end

    it 'returns the model version', :aggregate_failures do
      is_expected.to have_gitlab_http_status(:ok)
      expect(json_response['model_version']).not_to be_nil
      expect(json_response['model_version']['name']).to eq(name)
      expect(json_response['model_version']['version']).to eq(model_version.id.to_s)
    end

    describe 'Error States' do
      context 'when has access' do
        context 'and model name in incorrect' do
          let(:params) { { name: 'invalid-name', version: version, description: 'description-text' } }

          it 'throws error 400' do
            is_expected.to have_gitlab_http_status(:bad_request)
          end
        end

        context 'and version in incorrect' do
          let(:params) { { name: name, version: 'invalid-version', description: 'description-text' } }

          it 'throws error 400' do
            is_expected.to have_gitlab_http_status(:bad_request)
          end
        end

        context 'when user lacks write_model_registry rights' do
          before do
            allow(Ability).to receive(:allowed?).and_call_original
            allow(Ability).to receive(:allowed?)
                                .with(current_user, :write_model_registry, project)
                                .and_return(false)
          end

          it "is Not Found" do
            is_expected.to have_gitlab_http_status(:unauthorized)
          end
        end
      end

      it_behaves_like 'MLflow|an authenticated resource'
      it_behaves_like 'MLflow|a read/write model registry resource'
    end
  end

  describe 'POST /projects/:id/ml/mlflow/api/2.0/mlflow/model_versions/create' do
    let(:model_name) { model.name }
    let(:route) do
      "/projects/#{project_id}/ml/mlflow/api/2.0/mlflow/model-versions/create"
    end

    let(:params) { { name: model_name, description: 'description-text' } }
    let(:request) { post api(route), params: params, headers: headers }

    it 'returns the model', :aggregate_failures do
      is_expected.to have_gitlab_http_status(:ok)
      is_expected.to match_response_schema('ml/get_model_version')
    end

    it 'increments the version if a model version already exists' do
      m = create(:ml_model_versions, model: model, version: '1.0.0')

      is_expected.to have_gitlab_http_status(:ok)
      expect(json_response["model_version"]["version"]).to eq((m.id + 1).to_s)
    end

    describe 'user assigned version' do
      let(:params) do
        {
          'name' => model_name,
          'description' => 'description-text',
          'tags' => [{ 'key' => 'gitlab.version', 'value' => '1.2.3' }]
        }
      end

      it 'assigns the supplied version string via the gitlab tag' do
        is_expected.to have_gitlab_http_status(:ok)
        expect(json_response["model_version"]["tags"]).to match_array([{ "key" => 'gitlab.version',
                                                                         "value" => '1.2.3' }])
      end
    end

    describe 'Error States' do
      context 'when has access' do
        context 'and model does not exist' do
          let(:model_name) { 'foo' }

          it_behaves_like 'MLflow|Not Found - Resource Does Not Exist'
        end

        # TODO: Ensure consisted error responses https://gitlab.com/gitlab-org/gitlab/-/issues/429731
        context 'when a duplicate tag name is supplied' do
          let(:params) do
            { name: model_name, tags: [{ key: 'key1', value: 'value1' }, { key: 'key1', value: 'value2' }] }
          end

          it "returns a validation error", :aggregate_failures do
            expect(json_response).to include({ 'error_code' => 'INVALID_PARAMETER_VALUE' })
            expect(model.metadata.count).to be 0
          end
        end

        # TODO: Ensure consisted error responses https://gitlab.com/gitlab-org/gitlab/-/issues/429731
        context 'when an empty tag name is supplied' do
          let(:params) do
            { name: model_name, tags: [{ key: '', value: 'value1' }, { key: 'key1', value: 'value2' }] }
          end

          it "returns a validation error", :aggregate_failures do
            expect(json_response).to include({ 'error_code' => 'INVALID_PARAMETER_VALUE' })
            expect(model.metadata.count).to be 0
          end
        end
      end

      it_behaves_like 'MLflow|an authenticated resource'
      it_behaves_like 'MLflow|a read/write model registry resource'
    end
  end

  describe 'GET /projects/:id/ml/mlflow/api/2.0/mlflow/model-versions/get-download-uri' do
    let(:route) do
      "/projects/#{project_id}/ml/mlflow/api/2.0/mlflow/model-versions/get-download-uri?name=#{name}
&version=#{model_version.id}"
    end

    it 'returns the download-uri', :aggregate_failures do
      is_expected.to have_gitlab_http_status(:ok)
      expect(json_response).not_to be_nil
      expect(json_response.keys).to contain_exactly('artifact_uri')
      expect(json_response['artifact_uri']).not_to be_nil
      expect(json_response['artifact_uri']).to eq("mlflow-artifacts:/#{model_version.id}")
    end
  end
end
