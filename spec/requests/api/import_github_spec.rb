# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::ImportGithub do
  let(:token) { "asdasd12345" }
  let(:provider) { :github }
  let(:access_params) { { github_access_token: token } }

  describe "POST /import/github" do
    let(:user) { create(:user) }
    let(:project) { create(:project) }
    let(:provider_username) { user.username }
    let(:provider_user) { OpenStruct.new(login: provider_username) }
    let(:provider_repo) do
      OpenStruct.new(
        name: 'vim',
        full_name: "#{provider_username}/vim",
        owner: OpenStruct.new(login: provider_username)
      )
    end

    before do
      Grape::Endpoint.before_each do |endpoint|
        allow(endpoint).to receive(:client).and_return(double('client', user: provider_user, repository: provider_repo).as_null_object)
      end
    end

    after do
      Grape::Endpoint.before_each nil
    end

    it 'rejects requests when Github Importer is disabled' do
      stub_application_setting(import_sources: nil)

      post api("/import/github", user), params: {
        target_namespace: user.namespace_path,
        personal_access_token: token,
        repo_id: non_existing_record_id
      }

      expect(response).to have_gitlab_http_status(:forbidden)
    end

    it 'returns 201 response when the project is imported successfully' do
      allow(Gitlab::LegacyGithubImport::ProjectCreator)
        .to receive(:new).with(provider_repo, provider_repo.name, user.namespace, user, type: provider, **access_params)
          .and_return(double(execute: project))

      post api("/import/github", user), params: {
        target_namespace: user.namespace_path,
        personal_access_token: token,
        repo_id: non_existing_record_id
      }
      expect(response).to have_gitlab_http_status(:created)
      expect(json_response).to be_a Hash
      expect(json_response['name']).to eq(project.name)
    end

    it 'returns 201 response when the project is imported successfully from GHE' do
      allow(Gitlab::LegacyGithubImport::ProjectCreator)
        .to receive(:new).with(provider_repo, provider_repo.name, user.namespace, user, type: provider, **access_params)
          .and_return(double(execute: project))

      post api("/import/github", user), params: {
        target_namespace: user.namespace_path,
        personal_access_token: token,
        repo_id: non_existing_record_id,
        github_hostname: "https://github.somecompany.com/"
      }
      expect(response).to have_gitlab_http_status(:created)
      expect(json_response).to be_a Hash
      expect(json_response['name']).to eq(project.name)
    end

    it 'returns 422 response when user can not create projects in the chosen namespace' do
      other_namespace = create(:group, name: 'other_namespace')

      post api("/import/github", user), params: {
        target_namespace: other_namespace.name,
        personal_access_token: token,
        repo_id: non_existing_record_id
      }

      expect(response).to have_gitlab_http_status(:unprocessable_entity)
    end
  end
end
