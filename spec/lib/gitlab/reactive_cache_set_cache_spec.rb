# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::ReactiveCacheSetCache, :clean_gitlab_redis_cache do
  let_it_be(:project) { create(:project) }

  let(:cache_prefix) { 'cache_prefix' }
  let(:expires_in) { 10.minutes }
  let(:cache) { described_class.new(expires_in: expires_in) }

  describe '#cache_key' do
    subject { cache.cache_key(cache_prefix) }

    it 'includes the suffix' do
      expect(subject).to eq "#{Gitlab::Redis::Cache::CACHE_NAMESPACE}:#{cache_prefix}:set"
    end
  end

  describe '#read' do
    subject { cache.read(cache_prefix) }

    it { is_expected.to be_empty }

    context 'after item added' do
      before do
        cache.write(cache_prefix, 'test_item')
      end

      it { is_expected.to contain_exactly('test_item') }
    end
  end

  describe '#write' do
    it 'writes the value to the cache' do
      cache.write(cache_prefix, 'test_item')

      expect(cache.read(cache_prefix)).to contain_exactly('test_item')
    end

    it 'sets the expiry of the set' do
      cache.write(cache_prefix, 'test_item')

      expect(cache.ttl(cache_prefix)).to be_within(1).of(expires_in.seconds)
    end
  end

  describe '#clear_cache!', :use_clean_rails_redis_caching do
    it 'deletes the cached items' do
      # Cached key and value
      Rails.cache.write('test_item', 'test_value')
      # Add key to set
      cache.write(cache_prefix, 'test_item')

      expect(cache.read(cache_prefix)).to contain_exactly('test_item')
      cache.clear_cache!(cache_prefix)

      expect(cache.read(cache_prefix)).to be_empty
    end

    context 'when key size is large' do
      before do
        1001.times { |i| cache.write(cache_prefix, i) }
      end

      it 'sends multiple pipelines of 1000 unlinks' do
        Gitlab::Redis::Cache.with do |redis|
          if Gitlab::Redis::ClusterUtil.cluster?(redis)
            expect(redis).to receive(:pipelined).at_least(2).and_call_original
          else
            expect(redis).to receive(:pipelined).once.and_call_original
          end
        end

        cache.clear_cache!(cache_prefix)
      end
    end
  end

  describe '#include?' do
    subject { cache.include?(cache_prefix, 'test_item') }

    it { is_expected.to be(false) }

    context 'item added' do
      before do
        cache.write(cache_prefix, 'test_item')
      end

      it { is_expected.to be(true) }
    end
  end

  describe 'count' do
    subject { cache.count(cache_prefix) }

    it { is_expected.to be(0) }

    context 'item added' do
      before do
        cache.write(cache_prefix, 'test_item')
      end

      it { is_expected.to be(1) }
    end
  end
end
