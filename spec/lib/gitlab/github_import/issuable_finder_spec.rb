require 'spec_helper'

describe Gitlab::GithubImport::IssuableFinder, :clean_gitlab_redis_cache do
  let(:project) { double(:project, id: 4) }
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
  end

  describe '#cache_database_id' do
    it 'caches the ID of a database row' do
      expect(Gitlab::GithubImport::Caching)
        .to receive(:write)
        .with('github-import/issuable-finder/4/MergeRequest/1', 10)

      finder.cache_database_id(10)
    end
  end
end
