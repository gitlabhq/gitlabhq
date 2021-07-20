# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::ImportBitbucketServer do
  let(:base_uri) { "https://test:7990" }
  let(:user) { create(:user) }
  let(:token) { "asdasd12345" }
  let(:secret) { "sekrettt" }
  let(:project_key) { 'TES' }
  let(:repo_slug) { 'vim' }
  let(:repo) { { name: 'vim' } }

  describe "POST /import/bitbucket_server" do
    context 'with no optional parameters' do
      let_it_be(:project) { create(:project) }

      let(:client) { double(BitbucketServer::Client) }

      before do
        Grape::Endpoint.before_each do |endpoint|
          allow(endpoint).to receive(:client).and_return(client.as_null_object)
          allow(client).to receive(:repo).with(project_key, repo_slug).and_return(double(name: repo_slug))
        end
      end

      after do
        Grape::Endpoint.before_each nil
      end

      it 'returns 201 response when the project is imported successfully' do
        allow(Gitlab::BitbucketServerImport::ProjectCreator)
          .to receive(:new).with(project_key, repo_slug, anything, repo_slug, user.namespace, user, anything)
            .and_return(double(execute: project))

        post api("/import/bitbucket_server", user), params: {
          bitbucket_server_url: base_uri,
          bitbucket_server_username: user,
          personal_access_token: token,
          bitbucket_server_project: project_key,
          bitbucket_server_repo: repo_slug
        }

        expect(response).to have_gitlab_http_status(:created)
        expect(json_response).to be_a Hash
        expect(json_response['name']).to eq(project.name)
      end
    end

    context 'with a new project name' do
      let_it_be(:project) { create(:project, name: 'new-name') }

      let(:client) { instance_double(BitbucketServer::Client) }

      before do
        Grape::Endpoint.before_each do |endpoint|
          allow(endpoint).to receive(:client).and_return(client)
          allow(client).to receive(:repo).with(project_key, repo_slug).and_return(double(name: repo_slug))
        end
      end

      after do
        Grape::Endpoint.before_each nil
      end

      it 'returns 201 response when the project is imported successfully with a new project name' do
        allow(Gitlab::BitbucketServerImport::ProjectCreator)
        .to receive(:new).with(project_key, repo_slug, anything, project.name, user.namespace, user, anything)
        .and_return(double(execute: project))

        post api("/import/bitbucket_server", user), params: {
          bitbucket_server_url: base_uri,
          bitbucket_server_username: user,
          personal_access_token: token,
          bitbucket_server_project: project_key,
          bitbucket_server_repo: repo_slug,
          new_name: 'new-name'
        }

        expect(response).to have_gitlab_http_status(:created)
        expect(json_response).to be_a Hash
        expect(json_response['name']).to eq('new-name')
      end
    end

    context 'with an invalid URL' do
      let_it_be(:project) { create(:project, name: 'new-name') }

      let(:client) { instance_double(BitbucketServer::Client) }

      before do
        Grape::Endpoint.before_each do |endpoint|
          allow(endpoint).to receive(:client).and_return(client)
          allow(client).to receive(:repo).with(project_key, repo_slug).and_return(double(name: repo_slug))
        end
      end

      after do
        Grape::Endpoint.before_each nil
      end

      it 'returns 400 response due to a blocked URL' do
        allow(Gitlab::BitbucketServerImport::ProjectCreator)
        .to receive(:new).with(project_key, repo_slug, anything, project.name, user.namespace, user, anything)
        .and_return(double(execute: project))

        allow(Gitlab::UrlBlocker)
        .to receive(:blocked_url?)
        .and_return(true)
        post api("/import/bitbucket_server", user), params: {
          bitbucket_server_url: base_uri,
          bitbucket_server_username: user,
          personal_access_token: token,
          bitbucket_server_project: project_key,
          bitbucket_server_repo: repo_slug,
          new_name: 'new-name'
        }

        expect(response).to have_gitlab_http_status(:bad_request)
      end
    end

    context 'with a new namespace' do
      let(:bitbucket_client) { instance_double(BitbucketServer::Client) }

      before do
        Grape::Endpoint.before_each do |endpoint|
          allow(endpoint).to receive(:client).and_return(bitbucket_client)
          repo = double(name: repo_slug, full_path: "/other-namespace/#{repo_slug}")
          allow(bitbucket_client).to receive(:repo).with(project_key, repo_slug).and_return(repo)
        end
      end

      after do
        Grape::Endpoint.before_each nil
      end

      it 'returns 201 response when the project is imported successfully to a new namespace' do
        allow(Gitlab::BitbucketServerImport::ProjectCreator)
        .to receive(:new).with(project_key, repo_slug, anything, repo_slug, an_instance_of(Group), user, anything)
        .and_return(double(execute: create(:project, name: repo_slug)))

        post api("/import/bitbucket_server", user), params: {
          bitbucket_server_url: base_uri,
          bitbucket_server_username: user,
          personal_access_token: token,
          bitbucket_server_project: project_key,
          bitbucket_server_repo: repo_slug,
          new_namespace: 'new-namespace'
        }

        expect(response).to have_gitlab_http_status(:created)
        expect(json_response).to be_a Hash
        expect(json_response['full_path']).not_to eq("/#{user.namespace}/#{repo_slug}")
      end
    end

    context 'with a private inaccessible namespace' do
      let(:bitbucket_client) { instance_double(BitbucketServer::Client) }
      let(:project) { create(:project, import_type: 'bitbucket', creator_id: user.id, import_source: 'asd/vim', namespace: 'private-group/vim') }

      before do
        Grape::Endpoint.before_each do |endpoint|
          allow(endpoint).to receive(:client).and_return(bitbucket_client)
          repo = double(name: repo_slug, full_path: "/private-group/#{repo_slug}")
          allow(bitbucket_client).to receive(:repo).with(project_key, repo_slug).and_return(repo)
        end
      end

      after do
        Grape::Endpoint.before_each nil
      end

      it 'returns 401 response when user can not create projects in the chosen namespace' do
        allow(Gitlab::BitbucketServerImport::ProjectCreator)
        .to receive(:new).with(project_key, repo_slug, anything, repo_slug, an_instance_of(Group), user, anything)
        .and_return(double(execute: build(:project)))

        other_namespace = create(:group, :private, name: 'private-group')

        post api("/import/bitbucket_server", user), params: {
          bitbucket_server_url: base_uri,
          bitbucket_server_username: user,
          personal_access_token: token,
          bitbucket_server_project: project_key,
          bitbucket_server_repo: repo_slug,
          new_namespace: other_namespace.name
        }
        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context 'with an inaccessible bitbucket server instance' do
      let(:bitbucket_client) { instance_double(BitbucketServer::Client) }
      let(:project) { create(:project, import_type: 'bitbucket', creator_id: user.id, import_source: 'asd/vim', namespace: 'private-group/vim') }

      before do
        Grape::Endpoint.before_each do |endpoint|
          allow(endpoint).to receive(:client).and_return(bitbucket_client)
          allow(bitbucket_client).to receive(:repo).with(project_key, repo_slug).and_raise(::BitbucketServer::Connection::ConnectionError)
        end
      end

      after do
        Grape::Endpoint.before_each nil
      end

      it 'raises a connection error' do
        post api("/import/bitbucket_server", user), params: {
          bitbucket_server_url: base_uri,
          bitbucket_server_username: user,
          personal_access_token: token,
          bitbucket_server_project: project_key,
          bitbucket_server_repo: repo_slug,
          new_namespace: 'new-namespace'
        }
        expect(response).to have_gitlab_http_status(:bad_request)
      end
    end
  end
end
