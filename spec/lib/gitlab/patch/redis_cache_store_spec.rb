# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Patch::RedisCacheStore, :use_clean_rails_redis_caching, feature_category: :scalability do
  before do
    Rails.cache.write('x', 1)
    Rails.cache.write('y', 2)
    Rails.cache.write('z', 3)

    Rails.cache.write('{user1}:x', 1)
    Rails.cache.write('{user1}:y', 2)
    Rails.cache.write('{user1}:z', 3)
  end

  describe '#read_multi_mget' do
    it 'runs multi-key command if no cross-slot command is expected' do
      Rails.cache.redis.with do |redis|
        if Gitlab::Redis::ClusterUtil.cluster?(redis)
          expect(redis).to receive(:pipelined).once.and_call_original
        else
          expect(redis).not_to receive(:pipelined)
        end
      end

      expect(
        Rails.cache.fetch_multi('{user1}:x', '{user1}:y', '{user1}:z') { |key| key }
      ).to eq({ '{user1}:x' => 1, '{user1}:y' => 2, '{user1}:z' => 3 })
    end

    context 'when deleting large amount of keys' do
      it 'batches get into pipelines of 100' do
        Rails.cache.redis.with do |redis|
          expect(redis).to receive(:pipelined).at_least(2).and_call_original
        end

        Gitlab::Instrumentation::RedisClusterValidator.allow_cross_slot_commands do
          Rails.cache.read_multi(*Array.new(101) { |i| i })
        end
      end
    end

    shared_examples "fetches multiple keys" do |patched|
      it 'reads multiple keys' do
        if patched
          Rails.cache.redis.with do |redis|
            expect(redis).to receive(:pipelined).at_least(1).and_call_original
          end
        end

        Gitlab::Redis::Cache.with do |redis|
          unless Gitlab::Redis::ClusterUtil.cluster?(redis)
            expect(::Feature).to receive(:enabled?)
                                   .with(:feature_flag_state_logs, { default_enabled_if_undefined: nil, type: :ops })
                                   .exactly(:once)
                                   .and_call_original

            expect(::Feature).to receive(:enabled?)
                                   .with(:enable_rails_cache_pipeline_patch)
                                   .exactly(:once)
                                   .and_call_original
          end
        end

        expect(
          Gitlab::Instrumentation::RedisClusterValidator.allow_cross_slot_commands do
            # fetch_multi requires a block and we have to specifically test it
            # as it is used in the Gitlab project
            Rails.cache.fetch_multi('x', 'y', 'z') { |key| key }
          end
        ).to eq({ 'x' => 1, 'y' => 2, 'z' => 3 })
      end
    end

    shared_examples 'reading using non redis cache stores' do |klass|
      it 'does not affect non Redis::Cache cache stores' do
        klass.cache_store.redis.with do |redis|
          expect(redis).not_to receive(:pipelined) unless Gitlab::Redis::ClusterUtil.cluster?(redis)
        end

        Gitlab::Instrumentation::RedisClusterValidator.allow_cross_slot_commands do
          klass.cache_store.fetch_multi('x', 'y', 'z') { |key| key }
        end
      end
    end

    context 'when reading from non redis-cache stores' do
      it_behaves_like 'reading using non redis cache stores', Gitlab::Redis::FeatureFlag
      it_behaves_like 'reading using non redis cache stores', Gitlab::Redis::RepositoryCache
    end

    context 'when feature flag is disabled' do
      before do
        stub_feature_flags(enable_rails_cache_pipeline_patch: false)
      end

      it_behaves_like 'fetches multiple keys'
    end

    it_behaves_like 'fetches multiple keys', true
  end

  describe '#delete_multi_entries' do
    shared_examples "deletes multiple keys" do |patched|
      it 'deletes multiple keys' do
        if patched
          Rails.cache.redis.with do |redis|
            expect(redis).to receive(:pipelined).at_least(1).and_call_original
          end
        end

        Gitlab::Redis::Cache.with do |redis|
          unless Gitlab::Redis::ClusterUtil.cluster?(redis)
            expect(::Feature).to receive(:enabled?)
                                   .with(:feature_flag_state_logs, { default_enabled_if_undefined: nil, type: :ops })
                                   .exactly(:once)
                                   .and_call_original

            expect(::Feature).to receive(:enabled?)
                                   .with(:enable_rails_cache_pipeline_patch)
                                   .exactly(:once)
                                   .and_call_original
          end
        end

        expect(
          Gitlab::Instrumentation::RedisClusterValidator.allow_cross_slot_commands do
            Rails.cache.delete_multi(%w[x y z])
          end
        ).to eq(3)
      end
    end

    shared_examples 'deleting using non redis cache stores' do |klass|
      it 'does not affect non Redis::Cache cache stores' do
        klass.cache_store.redis.with do |redis|
          expect(redis).not_to receive(:pipelined) unless Gitlab::Redis::ClusterUtil.cluster?(redis)
        end

        Gitlab::Instrumentation::RedisClusterValidator.allow_cross_slot_commands do
          klass.cache_store.delete_multi(%w[x y z])
        end
      end
    end

    context 'when deleting from non redis-cache stores' do
      it_behaves_like 'deleting using non redis cache stores', Gitlab::Redis::FeatureFlag
      it_behaves_like 'deleting using non redis cache stores', Gitlab::Redis::RepositoryCache
    end

    context 'when deleting large amount of keys' do
      before do
        200.times { |i| Rails.cache.write(i, i) }
      end

      it 'calls pipeline multiple times' do
        Rails.cache.redis.with do |redis|
          # no expectation on number of times as it could vary depending on cluster size
          # if the Redis is a Redis Cluster
          expect(redis).to receive(:pipelined).at_least(2).and_call_original
        end

        expect(
          Gitlab::Instrumentation::RedisClusterValidator.allow_cross_slot_commands do
            Rails.cache.delete_multi(Array(0..199))
          end
        ).to eq(200)
      end
    end

    it 'runs multi-key command if no cross-slot command is expected' do
      Rails.cache.redis.with do |redis|
        if Gitlab::Redis::ClusterUtil.cluster?(redis)
          expect(redis).to receive(:pipelined).once.and_call_original
        else
          expect(redis).not_to receive(:pipelined)
        end
      end

      expect(
        Rails.cache.delete_multi(%w[{user1}:x {user1}:y {user1}:z])
      ).to eq(3)
    end

    context 'when feature flag is disabled' do
      before do
        stub_feature_flags(enable_rails_cache_pipeline_patch: false)
      end

      it_behaves_like 'deletes multiple keys'
    end

    it_behaves_like 'deletes multiple keys', true
  end
end
