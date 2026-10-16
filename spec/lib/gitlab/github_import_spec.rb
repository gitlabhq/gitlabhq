# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport, feature_category: :importers do
  let(:organization) { create(:common_organization) }
  let(:ghost_user) { Users::Internal.in_organization(organization.id).ghost }

  context 'github.com' do
    let(:project) { double(:project, unsafe_import_url: 'http://t0ken@github.com/user/repo.git', id: 1, group: nil) }

    it 'returns a new Client with a custom token' do
      import_data = double(:import_data, credentials: {})
      allow(project).to receive(:import_data).and_return(import_data)
      allow(import_data).to receive(:data).and_return({})

      expect(described_class::Client)
        .to receive(:new)
        .with('ghp_123', host: nil, parallel: true, per_page: 100, token_refresher: nil)

      described_class.new_client_for(project, token: 'ghp_123')
    end

    it 'returns a new Client with a token stored in the import data' do
      import_data = double(:import_data, credentials: { user: '123' })
      allow(project).to receive(:import_data).and_return(import_data)
      allow(import_data).to receive(:data).and_return({})

      expect(project)
        .to receive(:import_data)
        .and_return(import_data)

      expect(described_class::Client)
        .to receive(:new)
        .with('123', host: nil, parallel: true, per_page: 100, token_refresher: nil)

      described_class.new_client_for(project)
    end

    it 'returns the ID of the ghost user', :clean_gitlab_redis_shared_state do
      expect(described_class.ghost_user_id(organization.id)).to eq(ghost_user.id)
    end

    it 'caches the ghost user ID', :clean_gitlab_redis_cache do
      expect(Gitlab::Cache::Import::Caching)
        .to receive(:write)
        .once
        .and_call_original

      2.times do
        described_class.ghost_user_id(organization.id)
      end
    end

    it 'returns a new client with the pagination_limit stored in the import data' do
      import_data = double(:import_data, credentials: { user: '123' })
      allow(project).to receive(:import_data).and_return(import_data)
      allow(import_data).to receive(:data).and_return({ 'pagination_limit' => 50 })

      expect(described_class::Client)
        .to receive(:new)
        .with('123', host: nil, parallel: true, per_page: 50, token_refresher: nil)

      described_class.new_client_for(project)
    end
  end

  context 'GitHub Enterprise' do
    let(:project) { double(:project, unsafe_import_url: 'http://t0ken@github.another-domain.com/repo-org/repo.git', group: nil) }

    it 'returns a new Client with a custom token' do
      import_data = double(:import_data, credentials: {})
      allow(project).to receive(:import_data).and_return(import_data)
      allow(import_data).to receive(:data).and_return({})

      expect(described_class::Client)
        .to receive(:new)
        .with(
          'ghp_123',
          host: 'http://github.another-domain.com/api/v3', parallel: true, per_page: 100, token_refresher: nil
        )

      described_class.new_client_for(project, token: 'ghp_123')
    end

    it 'returns a new Client with a token stored in the import data' do
      import_data = double(:import_data, credentials: { user: '123' })
      allow(project).to receive(:import_data).and_return(import_data)
      allow(import_data).to receive(:data).and_return({})

      expect(project)
        .to receive(:import_data)
        .and_return(import_data)

      expect(described_class::Client)
        .to receive(:new)
        .with(
          '123',
          host: 'http://github.another-domain.com/api/v3', parallel: true, per_page: 100, token_refresher: nil
        )

      described_class.new_client_for(project)
    end

    it 'returns the ID of the ghost user', :clean_gitlab_redis_shared_state do
      expect(described_class.ghost_user_id(organization.id)).to eq(ghost_user.id)
    end

    it 'caches the ghost user ID', :clean_gitlab_redis_shared_state do
      expect(Gitlab::Cache::Import::Caching)
        .to receive(:write)
        .once
        .and_call_original

      2.times do
        described_class.ghost_user_id(organization.id)
      end
    end

    it 'formats the import url' do
      expect(described_class.formatted_import_url(project)).to eq('http://github.another-domain.com/api/v3')
    end
  end

  context 'with an expiring OAuth token', :freeze_time do
    let_it_be_with_reload(:project) { create(:project, :github_import) }

    let(:expires_at) { 1.hour.from_now.to_i }
    let(:token_url) { 'https://github.com/login/oauth/access_token' }
    let(:config) do
      Gitlab::Configs::Options.build(
        'app_id' => 'app-id',
        'app_secret' => 'app-secret',
        'args' => { 'client_options' => { 'site' => 'https://api.github.com', 'token_url' => token_url } }
      )
    end

    let!(:refresh_request) do
      stub_request(:post, token_url).to_return(
        status: 200,
        body: { access_token: 'ghu_new', refresh_token: 'ghr_new', expires_in: 28800 }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )
    end

    before do
      project.import_data.update!(credentials: { user: 'ghu_old', refresh_token: 'ghr_old', expires_at: expires_at })
      allow(Gitlab::Auth::OAuth::Provider).to receive(:config_for).with('github').and_return(config)
    end

    it 'gives the client a token refresher' do
      expect(described_class::Client).to receive(:new)
        .with('ghu_old', hash_including(token_refresher: an_instance_of(Proc)))

      described_class.new_client_for(project)
    end

    it 'refreshes the token and retries once when GitHub answers 401' do
      stub_request(:get, 'https://api.github.com/repos/foo/bar')
        .with(headers: { 'Authorization' => /ghu_old/ })
        .to_return(status: 401)
      stub_request(:get, 'https://api.github.com/repos/foo/bar')
        .with(headers: { 'Authorization' => /ghu_new/ })
        .to_return(
          status: 200,
          body: { full_name: 'foo/bar' }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      client = described_class.new_client_for(project)
      allow(client).to receive(:requests_remaining?).and_return(true)

      expect(client.repository('foo/bar')).to include(full_name: 'foo/bar')
      expect(refresh_request).to have_been_made.once
      expect(project.import_data.reload.credentials[:user]).to eq('ghu_new')
    end

    context 'when the token is about to expire' do
      let(:expires_at) { 1.minute.from_now.to_i }

      it 'refreshes it before building the client' do
        expect(described_class::Client).to receive(:new).with('ghu_new', anything)

        described_class.new_client_for(project)

        expect(refresh_request).to have_been_made.once
        expect(project.unsafe_import_url).to include('ghu_new')
      end
    end
  end
end
