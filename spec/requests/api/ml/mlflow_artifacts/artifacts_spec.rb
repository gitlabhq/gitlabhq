# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Ml::MlflowArtifacts::Artifacts, feature_category: :mlops do
  let_it_be(:project) { create(:project) }
  let_it_be(:developer) { create(:user, developer_of: project) }
  let_it_be(:another_project) { build(:project).tap { |p| p.add_developer(developer) } }

  let_it_be(:name) { 'a-model-name' }
  let_it_be(:version) { '0.0.1' }
  let_it_be(:model) { create(:ml_models, project: project, name: name) }
  let_it_be(:model_version) { create(:ml_model_versions, :with_package, model: model, version: version) }
  let_it_be(:package_file) { create(:package_file, :ml_model, package: model_version.package) }
  let_it_be(:model_version_no_package) { create(:ml_model_versions, model: model, version: '0.0.2') }

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

  describe 'GET /projects/:id/ml/mlflow/api/2.0/mlflow/artifacts' do
    let(:route) { "/projects/#{project_id}/ml/mlflow/api/2.0/mlflow-artifacts/artifacts?path=#{model_version.id}" }

    context 'when the user has access' do
      it 'returns a list of artifacts', :aggregate_failures do
        is_expected.to have_gitlab_http_status(:ok)
        expect(json_response).to have_key('files')
        expect(json_response['files']).to be_an_instance_of(Array)
        expect(json_response['files']).to have_attributes(size: 1)
        expect(json_response['files'].first).to include('path', 'is_dir', 'file_size')
        expect(json_response['files'].first['path']).to eq(package_file.file_name)
        expect(json_response['files'].first['is_dir']).to eq(false)
        expect(json_response['files'].first['file_size']).to eq(package_file.size)
      end
    end

    context 'when the user has access and checks for an directory' do
      let(:route) do
        "/projects/#{project_id}/ml/mlflow/api/2.0/mlflow-artifacts/artifacts?path=#{model_version.id}/MlModel"
      end

      it 'returns an empty list of artifacts', :aggregate_failures do
        is_expected.to have_gitlab_http_status(:ok)
        expect(json_response).to have_key('files')
        expect(json_response['files']).to be_an_instance_of(Array)
        expect(json_response['files']).to be_empty
      end
    end

    context 'when the user lacks read_model_registry rights' do
      before do
        allow(Ability).to receive(:allowed?).and_call_original
        allow(Ability).to receive(:allowed?)
                            .with(current_user, :read_model_registry, project)
                            .and_return(false)
      end

      it 'returns not found' do
        is_expected.to have_gitlab_http_status(:not_found)
      end
    end

    context 'when the model version has no package' do
      let(:route) do
        "/projects/#{project_id}/ml/mlflow/api/2.0/mlflow-artifacts/artifacts?path=#{model_version_no_package.id}"
      end

      it 'returns not found' do
        is_expected.to have_gitlab_http_status(:not_found)
      end
    end

    it_behaves_like 'MLflow|an authenticated resource'
    it_behaves_like 'MLflow|a read-only model registry resource'
  end

  describe 'GET /projects/:id/ml/mlflow/api/2.0/mlflow-artifacts/artifacts/:model_version/*file_path' do
    let(:file_path) { package_file.file_name }
    let(:route) do
      "/projects/#{project_id}/ml/mlflow/api/2.0/mlflow-artifacts/artifacts/#{model_version.id}/#{file_path}"
    end

    context 'when the user has access' do
      it 'returns the artifact file', :aggregate_failures do
        is_expected.to have_gitlab_http_status(:ok)
        expect(response.headers['Content-Disposition']).to match("attachment; filename=\"#{package_file.file_name}\"")
        expect(response.body)
          .to eq(package_file.file.read)
        expect(response.headers['Content-Length']).to eq(package_file.size.to_s)
      end
    end

    context 'when the file does not exist' do
      let(:file_path) { 'non_existent_file.txt' }

      it 'returns not found' do
        is_expected.to have_gitlab_http_status(:not_found)
      end
    end

    context 'when the user lacks read_model_registry rights' do
      before do
        allow(Ability).to receive(:allowed?).and_call_original
        allow(Ability).to receive(:allowed?)
                            .with(current_user, :read_model_registry, project)
                            .and_return(false)
      end

      it 'returns not found' do
        is_expected.to have_gitlab_http_status(:not_found)
      end
    end

    it_behaves_like 'MLflow|an authenticated resource'
    it_behaves_like 'MLflow|a read-only model registry resource'
  end
end
