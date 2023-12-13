# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport, feature_category: :importers do
  before do
    stub_feature_flags(github_importer_lower_per_page_limit: false)
  end

  context 'github.com' do
    let(:project) { double(:project, import_url: 'http://t0ken@github.com/user/repo.git', id: 1, group: nil) }

    it 'returns a new Client with a custom token' do
      expect(described_class::Client)
        .to receive(:new)
        .with('123', host: nil, parallel: true, per_page: 100)

      described_class.new_client_for(project, token: '123')
    end

    it 'returns a new Client with a token stored in the import data' do
      import_data = double(:import_data, credentials: { user: '123' })

      expect(project)
        .to receive(:import_data)
        .and_return(import_data)

      expect(described_class::Client)
        .to receive(:new)
        .with('123', host: nil, parallel: true, per_page: 100)

      described_class.new_client_for(project)
    end

    it 'returns the ID of the ghost user', :clean_gitlab_redis_cache do
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
  end

  context 'GitHub Enterprise' do
    let(:project) { double(:project, import_url: 'http://t0ken@github.another-domain.com/repo-org/repo.git', group: nil) }

    it 'returns a new Client with a custom token' do
      expect(described_class::Client)
        .to receive(:new)
        .with('123', host: 'http://github.another-domain.com/api/v3', parallel: true, per_page: 100)

      described_class.new_client_for(project, token: '123')
    end

    it 'returns a new Client with a token stored in the import data' do
      import_data = double(:import_data, credentials: { user: '123' })

      expect(project)
        .to receive(:import_data)
        .and_return(import_data)

      expect(described_class::Client)
        .to receive(:new)
        .with('123', host: 'http://github.another-domain.com/api/v3', parallel: true, per_page: 100)

      described_class.new_client_for(project)
    end

    it 'returns the ID of the ghost user', :clean_gitlab_redis_cache do
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

    it 'formats the import url' do
      expect(described_class.formatted_import_url(project)).to eq('http://github.another-domain.com/api/v3')
    end
  end

  describe '.per_page' do
    context 'when project group is present' do
      context 'when github_importer_lower_per_page_limit is enabled' do
        it 'returns lower per page value' do
          project = create(:project, import_url: 'http://t0ken@github.com/user/repo.git')
          group = create(:group, projects: [project])

          stub_feature_flags(github_importer_lower_per_page_limit: group)

          expect(described_class.per_page(project)).to eq(Gitlab::GithubImport::Client::LOWER_PER_PAGE)
        end
      end

      context 'when github_importer_lower_per_page_limit is disabled' do
        it 'returns default per page value' do
          project = double(:project, import_url: 'http://t0ken@github.com/user/repo.git', id: 1, group: create(:group))

          stub_feature_flags(github_importer_lower_per_page_limit: false)

          expect(described_class.per_page(project)).to eq(Gitlab::GithubImport::Client::DEFAULT_PER_PAGE)
        end
      end
    end

    context 'when project group is missing' do
      it 'returns default per page value' do
        project = double(:project, import_url: 'http://t0ken@github.com/user/repo.git', id: 1, group: nil)

        expect(described_class.per_page(project)).to eq(Gitlab::GithubImport::Client::DEFAULT_PER_PAGE)
      end
    end
  end
end
