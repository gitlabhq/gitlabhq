# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::BitbucketServerService, feature_category: :importers do
  let_it_be(:user) { create(:user) }

  let(:base_uri) { "https://test:7990" }
  let(:token) { "asdasd12345" }
  let(:secret) { "sekrettt" }
  let(:project_key) { 'TES' }
  let(:repo_slug) { 'vim' }
  let(:repo) do
    {
      name: 'vim',
      description: 'test',
      visibility_level: Gitlab::VisibilityLevel::PUBLIC,
      browse_url: 'http://repo.com/repo/repo',
      clone_url: 'http://repo.com/repo/repo.git'
    }
  end

  let(:client) { double(BitbucketServer::Client) }

  let(:credentials) { { base_uri: base_uri, user: user, password: token } }
  let(:params) { { bitbucket_server_url: base_uri, bitbucket_server_username: user, personal_access_token: token, bitbucket_server_project: project_key, bitbucket_server_repo: repo_slug } }

  subject { described_class.new(client, user, params) }

  before do
    allow(subject).to receive(:authorized?).and_return(true)
  end

  context 'execute' do
    before do
      allow(subject).to receive(:authorized?).and_return(true)
      allow(client).to receive(:repo).with(project_key, repo_slug).and_return(double(repo))
    end

    it 'tracks an access level event' do
      subject.execute(credentials)

      expect_snowplow_event(
        category: 'Import::BitbucketServerService',
        action: 'create',
        label: 'import_access_level',
        user: user,
        extra: { import_type: 'bitbucket', user_role: 'Owner' }
      )
    end
  end

  context 'when no repo is found' do
    before do
      allow(subject).to receive(:authorized?).and_return(true)
      allow(client).to receive(:repo).and_return(nil)
    end

    it 'returns an error' do
      result = subject.execute(credentials)

      expect(result).to include(
        message: "Project #{project_key}/#{repo_slug} could not be found",
        status: :error,
        http_status: :unprocessable_entity
      )
    end
  end

  context 'when import source is disabled' do
    before do
      stub_application_setting(import_sources: nil)
      allow(subject).to receive(:authorized?).and_return(true)
      allow(client).to receive(:repo).with(project_key, repo_slug).and_return(double(repo))
    end

    it 'returns forbidden' do
      result = subject.execute(credentials)

      expect(result).to include(
        status: :error,
        http_status: :forbidden
      )
    end
  end

  context 'when user is unauthorized' do
    before do
      allow(subject).to receive(:authorized?).and_return(false)
    end

    it 'returns an error' do
      result = subject.execute(credentials)

      expect(result).to include(
        message: "You don't have permissions to import this project",
        status: :error,
        http_status: :unauthorized
      )
    end
  end

  context 'verify url' do
    shared_examples 'denies local request' do
      before do
        allow(client).to receive(:repo).with(project_key, repo_slug).and_return(double(repo))
      end

      it 'does not allow requests' do
        result = subject.execute(credentials)
        expect(result[:status]).to eq(:error)
        expect(result[:message]).to include("Invalid URL:")
      end
    end

    context 'when host is localhost' do
      before do
        allow(subject).to receive(:url).and_return('https://localhost:3000')
      end

      include_examples 'denies local request'
    end

    context 'when host is on local network' do
      before do
        allow(subject).to receive(:url).and_return('https://192.168.0.191')
      end

      include_examples 'denies local request'
    end

    context 'when host is ftp protocol' do
      before do
        allow(subject).to receive(:url).and_return('ftp://testing')
      end

      include_examples 'denies local request'
    end
  end

  it 'raises an exception for unknown error causes' do
    exception = StandardError.new('Not Implemented')

    allow(client).to receive(:repo).and_raise(exception)

    expect(::Import::Framework::Logger).not_to receive(:error)

    expect { subject.execute(credentials) }.to raise_error(exception)
  end
end
