# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::MergeRequests::Mergeability::RedisInterface, :clean_gitlab_redis_cache do
  subject(:redis_interface) { described_class.new }

  let(:merge_check) { double(cache_key: '13') }
  let(:result_hash) { { test: 'test' } }
  let(:expected_key) { "#{merge_check.cache_key}:#{described_class::VERSION}" }

  describe '#save_check' do
    it 'saves the hash with the provided ttl' do
      expect(Gitlab::Redis::Cache.with { |redis| redis.get(expected_key) }).to be_nil

      redis_interface.save_check(merge_check: merge_check, result_hash: result_hash, ttl: 6.hours)

      expect(Gitlab::Redis::Cache.with { |redis| redis.get(expected_key) }).to eq result_hash.to_json
    end

    it 'uses the provided ttl for expiration' do
      redis_interface.save_check(merge_check: merge_check, result_hash: result_hash, ttl: 30.seconds)

      ttl = Gitlab::Redis::Cache.with { |redis| redis.ttl(expected_key) }
      expect(ttl).to be_within(1).of(30)
    end
  end

  describe '#delete_check' do
    it 'deletes the cached result' do
      Gitlab::Redis::Cache.with { |redis| redis.set(expected_key, result_hash.to_json) }

      expect(Gitlab::Redis::Cache.with { |redis| redis.exists?(expected_key) }).to be true

      redis_interface.delete_check(cache_key: merge_check.cache_key)

      expect(Gitlab::Redis::Cache.with { |redis| redis.exists?(expected_key) }).to be false
    end
  end

  describe '#retrieve_check' do
    it 'returns the hash' do
      Gitlab::Redis::Cache.with { |redis| redis.set(expected_key, result_hash.to_json) }

      expect(redis_interface.retrieve_check(merge_check: merge_check)).to eq result_hash
    end
  end
end
