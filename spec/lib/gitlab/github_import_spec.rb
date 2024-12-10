# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport, feature_category: :importers do
  context 'github.com' do
    let(:project) { double(:project, import_url: 'http://t0ken@github.com/user/repo.git', id: 1, group: nil) }

    it 'returns a new Client with a custom token' do
      import_data = double(:import_data)
      allow(project).to receive(:import_data).and_return(import_data)
      allow(import_data).to receive(:data).and_return({})

      expect(described_class::Client)
        .to receive(:new)
        .with('ghp_123', host: nil, parallel: true, per_page: 100)

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
        .with('123', host: nil, parallel: true, per_page: 100)

      described_class.new_client_for(project)
    end

    it 'returns the ID of the ghost user', :clean_gitlab_redis_shared_state do
      expect(described_class.ghost_user_id).to eq(Users::Internal.ghost.id)
    end

    it 'caches the ghost user ID', :clean_gitlab_redis_cache do
      expect(Gitlab::Cache::Import::Caching)
        .to receive(:write)
        .once
        .and_call_original

      2.times do
        described_class.ghost_user_id
      end
    end

    it 'returns a new client with the pagination_limit stored in the import data' do
      import_data = double(:import_data, credentials: { user: '123' })
      allow(project).to receive(:import_data).and_return(import_data)
      allow(import_data).to receive(:data).and_return({ 'pagination_limit' => 50 })

      expect(described_class::Client)
        .to receive(:new)
        .with('123', host: nil, parallel: true, per_page: 50)

      described_class.new_client_for(project)
    end
  end

  context 'GitHub Enterprise' do
    let(:project) { double(:project, import_url: 'http://t0ken@github.another-domain.com/repo-org/repo.git', group: nil) }

    it 'returns a new Client with a custom token' do
      import_data = double(:import_data)
      allow(project).to receive(:import_data).and_return(import_data)
      allow(import_data).to receive(:data).and_return({})

      expect(described_class::Client)
        .to receive(:new)
        .with('ghp_123', host: 'http://github.another-domain.com/api/v3', parallel: true, per_page: 100)

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
        .with('123', host: 'http://github.another-domain.com/api/v3', parallel: true, per_page: 100)

      described_class.new_client_for(project)
    end

    it 'returns the ID of the ghost user', :clean_gitlab_redis_shared_state do
      expect(described_class.ghost_user_id).to eq(Users::Internal.ghost.id)
    end

    it 'caches the ghost user ID', :clean_gitlab_redis_shared_state do
      expect(Gitlab::Cache::Import::Caching)
        .to receive(:write)
        .once
        .and_call_original

      2.times do
        described_class.ghost_user_id
      end
    end

    it 'formats the import url' do
      expect(described_class.formatted_import_url(project)).to eq('http://github.another-domain.com/api/v3')
    end
  end
end
