# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::RepositorySetCache, :clean_gitlab_redis_cache do
  let_it_be(:project) { create(:project) }
  let(:repository) { project.repository }
  let(:namespace) { "#{repository.full_path}:#{project.id}" }
  let(:cache) { described_class.new(repository) }

  describe '#cache_key' do
    subject { cache.cache_key(:foo) }

    it 'includes the namespace' do
      is_expected.to eq("foo:#{namespace}:set")
    end

    context 'with a given namespace' do
      let(:extra_namespace) { 'my:data' }
      let(:cache) { described_class.new(repository, extra_namespace: extra_namespace) }

      it 'includes the full namespace' do
        is_expected.to eq("foo:#{namespace}:#{extra_namespace}:set")
      end
    end
  end

  describe '#expire' do
    it 'expires the given key from the cache' do
      cache.write(:foo, ['value'])

      expect(cache.read(:foo)).to contain_exactly('value')
      expect(cache.expire(:foo)).to eq(1)
      expect(cache.read(:foo)).to be_empty
    end
  end

  describe '#exist?' do
    it 'checks whether the key exists' do
      expect(cache.exist?(:foo)).to be(false)

      cache.write(:foo, ['value'])

      expect(cache.exist?(:foo)).to be(true)
    end
  end

  describe '#fetch' do
    let(:blk) { -> { ['block value'] } }

    subject { cache.fetch(:foo, &blk) }

    it 'fetches the key from the cache when filled' do
      cache.write(:foo, ['value'])

      is_expected.to contain_exactly('value')
    end

    it 'writes the value of the provided block when empty' do
      cache.expire(:foo)

      is_expected.to contain_exactly('block value')
      expect(cache.read(:foo)).to contain_exactly('block value')
    end
  end

  describe '#include?' do
    it 'checks inclusion in the Redis set' do
      cache.write(:foo, ['value'])

      expect(cache.include?(:foo, 'value')).to be(true)
      expect(cache.include?(:foo, 'bar')).to be(false)
    end
  end
end
