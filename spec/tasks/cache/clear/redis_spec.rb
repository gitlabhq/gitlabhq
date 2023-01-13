# frozen_string_literal: true

require 'rake_helper'

RSpec.describe 'clearing redis cache', :clean_gitlab_redis_repository_cache, :clean_gitlab_redis_cache,
               :silence_stdout, feature_category: :redis do
  before do
    Rake.application.rake_require 'tasks/cache'
  end

  let(:keys_size_changed) { -1 }

  shared_examples 'clears the cache' do
    it { expect { run_rake_task('cache:clear:redis') }.to change { redis_keys.size }.by(keys_size_changed) }
  end

  describe 'clearing pipeline status cache' do
    let(:pipeline_status) do
      project = create(:project, :repository)
      create(:ci_pipeline, project: project).project.pipeline_status
    end

    context 'when use_primary_and_secondary_stores_for_repository_cache MultiStore FF is enabled' do
      # Initially, project:{id}:pipeline_status is explicitly cached in Gitlab::Redis::Cache, whereas repository is
      # cached in Rails.cache (which is a NullStore).
      # With the MultiStore feature flag enabled, we use Gitlab::Redis::RepositoryCache instance as primary store and
      # Gitlab::Redis::Cache as secondary store.
      # This ends up storing 2 extra keys (exists? and root_ref) in both Gitlab::Redis::RepositoryCache and
      # Gitlab::Redis::Cache instances when loading project.pipeline_status
      let(:keys_size_changed) { -3 }

      before do
        stub_feature_flags(use_primary_and_secondary_stores_for_repository_cache: true)
        allow(pipeline_status).to receive(:loaded).and_return(nil)
      end

      it 'clears pipeline status cache' do
        expect { run_rake_task('cache:clear:redis') }.to change { pipeline_status.has_cache? }
      end

      it_behaves_like 'clears the cache'
    end

    context 'when use_primary_and_secondary_stores_for_repository_cache and
            use_primary_store_as_default_for_repository_cache feature flags are disabled' do
      before do
        stub_feature_flags(use_primary_and_secondary_stores_for_repository_cache: false)
        stub_feature_flags(use_primary_store_as_default_for_repository_cache: false)
        allow(pipeline_status).to receive(:loaded).and_return(nil)
      end

      it_behaves_like 'clears the cache'
    end
  end

  describe 'clearing set caches' do
    context 'repository set' do
      let(:project) { create(:project) }
      let(:repository) { project.repository }

      let(:cache) { Gitlab::RepositorySetCache.new(repository) }

      before do
        cache.write(:foo, [:bar])
      end

      it_behaves_like 'clears the cache'
    end

    context 'reactive cache set' do
      let(:cache) { Gitlab::ReactiveCacheSetCache.new }

      before do
        cache.write(:foo, :bar)
      end

      it_behaves_like 'clears the cache'
    end
  end

  def redis_keys
    Gitlab::Redis::Cache.with { |redis| redis.scan(0, match: "*") }.last
  end
end
