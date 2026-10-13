# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::IssuableFinder, :clean_gitlab_redis_shared_state, feature_category: :importers do
  let_it_be(:project) { create(:project) }
  let_it_be(:merge_request) { create(:merge_request, source_project: project) }
  let(:issue) { double(:issue, issuable_type: 'MergeRequest', issuable_id: merge_request.iid) }
  let(:finder) { described_class.new(project, issue) }

  describe '#database_id' do
    it 'returns nil if object does not exist' do
      missing_issue = double(:issue, issuable_type: 'MergeRequest', issuable_id: 999)

      expect(described_class.new(project, missing_issue).database_id).to be_nil
    end

    it 'fetches object id from database if not in cache' do
      expect(finder.database_id).to eq(merge_request.id)
    end

    it 'fetches object id from cache if present' do
      finder.cache_database_id(10)

      expect(finder.database_id).to eq(10)
    end

    it 'returns nil and skips database read if cache has no record' do
      finder.cache_database_id(-1)

      expect(finder.database_id).to be_nil
    end

    it 'raises TypeError when the object is not supported' do
      finder = described_class.new(project, double(:issue))

      expect { finder.database_id }.to raise_error(TypeError)
    end

    it 'reads cache value with longer timeout' do
      expect(Gitlab::Cache::Import::Caching)
        .to receive(:read)
        .with(anything, timeout: Gitlab::Cache::Import::Caching::LONGER_TIMEOUT, refresh: true)

      finder.database_id
    end
  end

  describe '#cache_database_id' do
    it 'caches the ID of a database row with longer timeout' do
      expect(Gitlab::Cache::Import::Caching)
        .to receive(:write)
        .with(
          "github-import/issuable-finder/#{project.id}/MergeRequest/#{merge_request.iid}",
          10,
          timeout: Gitlab::Cache::Import::Caching::LONGER_TIMEOUT
        )

      finder.cache_database_id(10)
    end
  end
end
