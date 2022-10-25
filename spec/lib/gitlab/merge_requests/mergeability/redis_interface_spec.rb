# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::MergeRequests::Mergeability::RedisInterface, :clean_gitlab_redis_cache do
  subject(:redis_interface) { described_class.new }

  let(:merge_check) { double(cache_key: '13') }
  let(:result_hash) { { test: 'test' } }
  let(:expected_key) { "#{merge_check.cache_key}:#{described_class::VERSION}" }

  describe '#save_check' do
    it 'saves the hash' do
      expect(Gitlab::Redis::Cache.with { |redis| redis.get(expected_key) }).to be_nil

      redis_interface.save_check(merge_check: merge_check, result_hash: result_hash)

      expect(Gitlab::Redis::Cache.with { |redis| redis.get(expected_key) }).to eq result_hash.to_json
    end
  end

  describe '#retrieve_check' do
    it 'returns the hash' do
      Gitlab::Redis::Cache.with { |redis| redis.set(expected_key, result_hash.to_json) }

      expect(redis_interface.retrieve_check(merge_check: merge_check)).to eq result_hash
    end
  end
end
