# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::GithubService, feature_category: :importers do
  let_it_be(:user) { create(:user) }

  let(:token) { 'complex-token' }
  let(:access_params) { { github_access_token: 'ghp_complex-token' } }
  let(:settings) { instance_double(Gitlab::GithubImport::Settings) }
  let(:user_namespace_path) { user.namespace_path }
  let(:optional_stages) { nil }
  let(:timeout_strategy) { "optimistic" }
  let(:pagination_limit) { nil }
  let(:params) do
    {
      repo_id: 123,
      new_name: 'new_repo',
      target_namespace: user_namespace_path,
      optional_stages: optional_stages,
      timeout_strategy: timeout_strategy,
      pagination_limit: pagination_limit
    }
  end

  let(:client) { Gitlab::GithubImport::Client.new(token) }
  let(:project_double) { instance_double(Project, persisted?: true) }

  subject(:github_importer) { described_class.new(client, user, params) }

  before do
    allow(client).to receive_message_chain(:octokit, :rate_limit, :limit)
    allow(client).to receive_message_chain(:octokit, :rate_limit, :remaining).and_return(100)
    allow(Gitlab::GithubImport::Settings).to receive(:new).with(project_double).and_return(settings)
    allow(settings)
      .to receive(:write)
      .with(
        optional_stages: optional_stages,
        timeout_strategy: timeout_strategy,
        pagination_limit: pagination_limit
      )
  end

  context 'with an input error' do
    let(:exception) { Octokit::ClientError.new(status: 404, body: 'Not Found') }

    before do
      allow(client).to receive_message_chain(:octokit, :repository).and_raise(exception)
    end

    it 'logs the original error' do
      expect(::Import::Framework::Logger).to receive(:error).with({
        message: 'Import failed because of a GitHub error',
        status: 404,
        error: 'Not Found'
      }).and_call_original

      github_importer.execute(access_params, :github)
    end

    it 'returns an error with message and code' do
      result = github_importer.execute(access_params, :github)

      expect(result).to include(
        message: s_('GithubImport|Import failed because of a GitHub error: Not Found (HTTP 404)'),
        status: :error,
        http_status: :unprocessable_entity
      )
    end
  end

  it 'raises an exception for unknown error causes' do
    exception = StandardError.new('Not Implemented')

    expect(client).to receive_message_chain(:octokit, :repository).and_raise(exception)

    expect(::Import::Framework::Logger).not_to receive(:error)

    expect { github_importer.execute(access_params, :github) }.to raise_error(exception)
  end

  describe 'access token validation' do
    before do
      allow(github_importer).to receive(:authorized?).and_return(true)
      allow(client).to receive_message_chain(:octokit, :repository).and_return({ status: 200 })

      allow_next_instance_of(Gitlab::LegacyGithubImport::ProjectCreator) do |creator|
        allow(creator).to receive(:execute).and_return(project_double)
      end
    end

    context 'when the caller is not a github import' do
      let(:repository_double) do
        {
          name: 'vim',
          description: 'test',
          full_name: 'test/vim',
          clone_url: 'http://repo.com/repo/repo.git',
          private: false,
          has_wiki?: false
        }
      end

      before do
        allow(github_importer).to receive(:repo).and_return(repository_double)
      end

      it 'does not validate access token' do
        expect(github_importer).not_to receive(:validate_access_token)

        github_importer.execute(access_params, :gitea)
      end
    end

    context 'when the caller is a github import' do
      let(:repository_double) { { name: 'repository', size: 99 } }

      before do
        allow(github_importer).to receive(:repo).and_return(repository_double)
      end

      it 'validates access token' do
        expect(github_importer).to receive(:validate_access_token)

        github_importer.execute(access_params, :github)
      end
    end

    context 'when an unexpected Octokit error is raised' do
      let(:exception) { Octokit::Error.new(status: 500, body: 'Internal Server Error') }

      it 'rescues and logs the error' do
        allow(client).to receive_message_chain(:octokit, :repository).and_raise(exception)
        expect(::Import::Framework::Logger).to receive(:error).with({
          message: 'Import failed because of a GitHub error',
          status: 500,
          error: 'Internal Server Error'
        }).and_call_original

        github_importer.execute(access_params, :github)
      end
    end

    context 'when a forbidden error is raised when fetching the repository information' do
      let(:exception) { Octokit::Forbidden.new(status: 403, body: 'Forbidden') }
      let(:optional_stages) { { collaborators_import: false } }

      it 'returns an error' do
        allow(client).to receive_message_chain(:octokit, :repository).and_raise(exception)

        expect(github_importer.execute(access_params, :github)).to include(forbidden_token_error)
      end
    end

    context 'when the collaborator import option is true, and an error is raised when fetching the collaborators' do
      let(:optional_stages) { { collaborators_import: true } }
      let(:exception) { Octokit::Unauthorized.new(status: 401, body: 'Unauthorized') }

      it 'returns an error' do
        allow(client).to receive_message_chain(:octokit, :repository).and_return({ status: 200 })
        allow(client).to receive_message_chain(:octokit, :collaborators).and_raise(exception)

        expect(github_importer.execute(access_params, :github)).to include(unauthorized_token_error)
        github_importer.execute(access_params, :github)
      end
    end
  end

  context 'when import source is disabled' do
    let(:repository_double) do
      {
        name: 'vim',
        description: 'test',
        full_name: 'test/vim',
        clone_url: 'http://repo.com/repo/repo.git',
        private: false,
        has_wiki?: false
      }
    end

    before do
      stub_application_setting(import_sources: nil)
      allow(client).to receive_message_chain(:octokit, :repository).and_return({ status: 200 })
      allow(client).to receive(:repository).and_return(repository_double)
      allow(Gitlab::GithubImport::Settings).to receive(:new).and_call_original
    end

    it 'returns forbidden' do
      result = github_importer.execute(access_params, :github)

      expect(result).to include(
        status: :error,
        http_status: :forbidden
      )
    end
  end

  context 'when a blocked/local URL is used as github_hostname' do
    let(:message) { 'Error while attempting to import from GitHub' }
    let(:error) { "Invalid URL: #{url}" }

    before do
      stub_application_setting(allow_local_requests_from_web_hooks_and_services: false)
    end

    where(url: %w[https://localhost https://10.0.0.1])

    with_them do
      it 'returns and logs an error' do
        allow(github_importer).to receive(:url).and_return(url)

        expect(::Import::Framework::Logger).to receive(:error).with({
          message: message,
          error: error
        }).and_call_original
        expect(github_importer.execute(access_params, :github)).to include(blocked_url_error(url))
      end
    end
  end

  context 'when target_namespace is blank' do
    before do
      params[:target_namespace] = ''
    end

    it 'raises an exception' do
      expect do
        github_importer.execute(access_params,
          :github)
      end.to raise_error(ArgumentError, s_('GithubImport|Target namespace is required'))
    end
  end

  context 'when namespace to import repository into does not exist' do
    before do
      params[:target_namespace] = 'unknown_path'
    end

    it 'returns an error' do
      expect(github_importer.execute(access_params, :github)).to include(not_existed_namespace_error)
    end
  end

  context 'when user has no permissions to import repository into the specified namespace' do
    let_it_be(:group) { create(:group) }

    before do
      params[:target_namespace] = group.full_path
    end

    it 'returns an error' do
      expect(github_importer.execute(access_params, :github)).to include(taken_namespace_error)
    end
  end

  def forbidden_token_error
    {
      status: :error,
      http_status: :unprocessable_entity,
      message: "Your GitHub personal access token does not have read access to the repository. " \
               "Please use a classic GitHub personal access token with the `repo` scope. Fine-grained tokens are not " \
               "supported."
    }
  end

  def unauthorized_token_error
    {
      status: :error,
      http_status: :unprocessable_entity,
      message: "Your GitHub personal access token does not have read access to collaborators. " \
               "Please use a classic GitHub personal access token with the `read:org` scope. Fine-grained tokens are " \
               "not supported."
    }
  end

  def blocked_url_error(url)
    {
      status: :error,
      http_status: :bad_request,
      message: "Invalid URL: #{url}"
    }
  end

  def not_existed_namespace_error
    {
      status: :error,
      http_status: :unprocessable_entity,
      message: s_('GithubImport|Namespace or group to import repository into does not exist.')
    }
  end

  def taken_namespace_error
    {
      status: :error,
      http_status: :unprocessable_entity,
      message: s_('GithubImport|You are not allowed to import projects in this namespace.')
    }
  end
end
