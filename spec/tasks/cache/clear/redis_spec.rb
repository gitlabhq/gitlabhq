# frozen_string_literal: true

require 'rake_helper'

RSpec.describe 'clearing redis cache', :clean_gitlab_redis_cache, :silence_stdout do
  before do
    Rake.application.rake_require 'tasks/cache'
  end

  shared_examples 'clears the cache' do
    it { expect { run_rake_task('cache:clear:redis') }.to change { redis_keys.size }.by(-1) }
  end

  describe 'clearing pipeline status cache' do
    let(:pipeline_status) do
      project = create(:project, :repository)
      create(:ci_pipeline, project: project).project.pipeline_status
    end

    before do
      allow(pipeline_status).to receive(:loaded).and_return(nil)
    end

    it 'clears pipeline status cache' do
      expect { run_rake_task('cache:clear:redis') }.to change { pipeline_status.has_cache? }
    end

    it_behaves_like 'clears the cache'
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
