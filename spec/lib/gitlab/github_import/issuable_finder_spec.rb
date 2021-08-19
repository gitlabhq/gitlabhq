# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::IssuableFinder, :clean_gitlab_redis_cache do
  let(:project) { double(:project, id: 4, group: nil) }
  let(:issue) do
    double(:issue, issuable_type: MergeRequest, iid: 1)
  end

  let(:finder) { described_class.new(project, issue) }

  describe '#database_id' do
    it 'returns nil when no cache is in place' do
      expect(finder.database_id).to be_nil
    end

    it 'returns the ID of an issuable when the cache is in place' do
      finder.cache_database_id(10)

      expect(finder.database_id).to eq(10)
    end

    it 'raises TypeError when the object is not supported' do
      finder = described_class.new(project, double(:issue))

      expect { finder.database_id }.to raise_error(TypeError)
    end

    context 'when group is present' do
      context 'when github_importer_single_endpoint_notes_import feature flag is enabled' do
        it 'reads cache value with longer timeout' do
          project = create(:project, import_url: 'http://t0ken@github.com/user/repo.git')
          group = create(:group, projects: [project])

          stub_feature_flags(github_importer_single_endpoint_notes_import: group)

          expect(Gitlab::Cache::Import::Caching)
            .to receive(:read)
            .with(anything, timeout: Gitlab::Cache::Import::Caching::LONGER_TIMEOUT)

          described_class.new(project, issue).database_id
        end
      end

      context 'when github_importer_single_endpoint_notes_import feature flag is disabled' do
        it 'reads cache value with default timeout' do
          project = double(:project, id: 4, group: create(:group))

          stub_feature_flags(github_importer_single_endpoint_notes_import: false)

          expect(Gitlab::Cache::Import::Caching)
            .to receive(:read)
            .with(anything, timeout: Gitlab::Cache::Import::Caching::TIMEOUT)

          described_class.new(project, issue).database_id
        end
      end
    end
  end

  describe '#cache_database_id' do
    it 'caches the ID of a database row' do
      expect(Gitlab::Cache::Import::Caching)
        .to receive(:write)
        .with('github-import/issuable-finder/4/MergeRequest/1', 10, timeout: 86400)

      finder.cache_database_id(10)
    end

    context 'when group is present' do
      context 'when github_importer_single_endpoint_notes_import feature flag is enabled' do
        it 'caches value with longer timeout' do
          project = create(:project, import_url: 'http://t0ken@github.com/user/repo.git')
          group = create(:group, projects: [project])

          stub_feature_flags(github_importer_single_endpoint_notes_import: group)

          expect(Gitlab::Cache::Import::Caching)
            .to receive(:write)
            .with(anything, anything, timeout: Gitlab::Cache::Import::Caching::LONGER_TIMEOUT)

          described_class.new(project, issue).cache_database_id(10)
        end
      end

      context 'when github_importer_single_endpoint_notes_import feature flag is disabled' do
        it 'caches value with default timeout' do
          project = double(:project, id: 4, group: create(:group))

          stub_feature_flags(github_importer_single_endpoint_notes_import: false)

          expect(Gitlab::Cache::Import::Caching)
            .to receive(:write)
            .with(anything, anything, timeout: Gitlab::Cache::Import::Caching::TIMEOUT)

          described_class.new(project, issue).cache_database_id(10)
        end
      end
    end
  end
end
