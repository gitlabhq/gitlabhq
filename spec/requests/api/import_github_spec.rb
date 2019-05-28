require 'spec_helper'

describe API::ImportGithub do
  include ApiHelpers

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
        allow(endpoint).to receive(:client).and_return(double('client', user: provider_user, repo: provider_repo).as_null_object)
      end
    end

    it 'returns 201 response when the project is imported successfully' do
      allow(Gitlab::LegacyGithubImport::ProjectCreator)
        .to receive(:new).with(provider_repo, provider_repo.name, user.namespace, user, access_params, type: provider)
          .and_return(double(execute: project))

      post api("/import/github", user), params: {
        target_namespace: user.namespace_path,
        personal_access_token: token,
        repo_id: 1234
      }
      expect(response).to have_gitlab_http_status(201)
      expect(json_response).to be_a Hash
      expect(json_response['name']).to eq(project.name)
    end

    it 'returns 422 response when user can not create projects in the chosen namespace' do
      other_namespace = create(:group, name: 'other_namespace')

      post api("/import/github", user), params: {
        target_namespace: other_namespace.name,
        personal_access_token: token,
        repo_id: 1234
      }

      expect(response).to have_gitlab_http_status(422)
    end
  end
end
