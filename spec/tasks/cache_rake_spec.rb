# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'clearing redis cache', :clean_gitlab_redis_repository_cache, :clean_gitlab_redis_cache,
  :silence_stdout, :use_null_store_as_repository_cache, feature_category: :redis do
  before do
    Rake.application.rake_require 'tasks/cache'
  end

  let(:keys_size_changed) { -1 }

  shared_examples 'clears the cache' do |redis|
    it { expect { run_rake_task('cache:clear:redis') }.to change { redis_keys(redis).size }.by(keys_size_changed) }
  end

  describe 'clearing pipeline status cache' do
    let(:pipeline_status) do
      project = create(:project, :repository)
      create(:ci_pipeline, project: project).project.pipeline_status
    end

    before do
      allow(pipeline_status).to receive(:loaded).and_return(nil)
    end

    it_behaves_like 'clears the cache', Gitlab::Redis::Cache
  end

  describe 'clearing set caches' do
    context 'repository set' do
      let(:project) { create(:project) }
      let(:repository) { project.repository }

      let(:cache) { Gitlab::RepositorySetCache.new(repository) }

      before do
        cache.write(:foo, [:bar])
      end

      it_behaves_like 'clears the cache', Gitlab::Redis::RepositoryCache
    end

    context 'reactive cache set' do
      let(:cache) { Gitlab::ReactiveCacheSetCache.new }

      before do
        cache.write(:foo, :bar)
      end

      it_behaves_like 'clears the cache', Gitlab::Redis::Cache
    end
  end

  def redis_keys(redis_instance)
    # multiple scans to look across different shards if cache is using a Redis Cluster
    cursor, scanned_keys = redis_instance.with { |redis| redis.scan(0, match: "*") }
    while cursor != "0"
      cursor, keys = redis_instance.with { |redis| redis.scan(cursor, match: "*") }
      scanned_keys << keys
    end
    scanned_keys.flatten
  end
end
