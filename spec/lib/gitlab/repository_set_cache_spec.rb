# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::RepositorySetCache, :clean_gitlab_redis_repository_cache, feature_category: :source_code_management do
  let_it_be(:project) { create(:project) }

  let(:repository) { project.repository }
  let(:namespace) { "#{repository.full_path}:#{project.id}" }
  let(:gitlab_cache_namespace) { Gitlab::Redis::Cache::CACHE_NAMESPACE }
  let(:cache) { described_class.new(repository) }

  describe '#cache_key' do
    subject { cache.cache_key(:foo) }

    shared_examples 'cache_key examples' do
      it 'includes the namespace' do
        is_expected.to eq("#{gitlab_cache_namespace}:foo:#{namespace}:set")
      end

      context 'with a given namespace' do
        let(:extra_namespace) { 'my:data' }
        let(:cache) { described_class.new(repository, extra_namespace: extra_namespace) }

        it 'includes the full namespace' do
          is_expected.to eq("#{gitlab_cache_namespace}:foo:#{namespace}:#{extra_namespace}:set")
        end
      end
    end

    describe 'project repository' do
      it_behaves_like 'cache_key examples' do
        let(:repository) { project.repository }
      end
    end

    describe 'personal snippet repository' do
      let_it_be(:personal_snippet) { create(:personal_snippet) }

      let(:namespace) { repository.full_path }

      it_behaves_like 'cache_key examples' do
        let(:repository) { personal_snippet.repository }
      end
    end

    describe 'project snippet repository' do
      let_it_be(:project_snippet) { create(:project_snippet, project: project) }

      it_behaves_like 'cache_key examples' do
        let(:repository) { project_snippet.repository }
      end
    end
  end

  describe '#write' do
    subject(:write_cache) { cache.write('branch_names', ['main']) }

    it 'writes the value to the cache' do
      write_cache

      cursor, redis_keys = Gitlab::Redis::RepositoryCache.with { |redis| redis.scan(0, match: "*") }
      while cursor != "0"
        cursor, keys = Gitlab::Redis::RepositoryCache.with { |redis| redis.scan(cursor, match: "*") }
        redis_keys << keys
      end

      expect(redis_keys.flatten).to include("#{gitlab_cache_namespace}:branch_names:#{namespace}:set")
      expect(cache.fetch('branch_names')).to contain_exactly('main')
    end

    it 'sets the expiry of the set' do
      write_cache

      expect(cache.ttl('branch_names')).to be_within(1).of(cache.expires_in.seconds)
    end
  end

  describe '#expire' do
    subject { cache.expire(*keys) }

    before do
      cache.write(:foo, ['value'])
      cache.write(:bar, ['value2'])
    end

    it 'actually wrote the values' do
      expect(cache.read(:foo)).to contain_exactly('value')
      expect(cache.read(:bar)).to contain_exactly('value2')
    end

    context 'single key' do
      let(:keys) { %w[foo] }

      it { is_expected.to eq(1) }

      it 'deletes the given key from the cache' do
        subject

        expect(cache.read(:foo)).to be_empty
      end
    end

    context 'multiple keys' do
      let(:keys) { %w[foo bar] }

      it { is_expected.to eq(2) }

      it 'deletes the given keys from the cache' do
        subject

        expect(cache.read(:foo)).to be_empty
        expect(cache.read(:bar)).to be_empty
      end
    end

    context 'no keys' do
      let(:keys) { [] }

      it { is_expected.to eq(0) }
    end

    context 'when deleting over 1000 keys' do
      it 'deletes in batches of 1000' do
        Gitlab::Redis::RepositoryCache.with do |redis|
          # In a Redis Cluster, we do not want a pipeline to have too many keys
          # but in a standalone Redis, multi-key commands can be used.
          if ::Gitlab::Redis::ClusterUtil.cluster?(redis)
            expect(redis).to receive(:pipelined).at_least(2).and_call_original
          else
            expect(redis).to receive(:unlink).and_call_original
          end
        end

        cache.expire(*(Array.new(1001) { |i| i }))
      end
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

  describe '#search' do
    subject do
      cache.search(:foo, 'val*') do
        %w[value helloworld notvalmatch]
      end
    end

    it 'returns search pattern matches from the key' do
      is_expected.to contain_exactly('value')
    end
  end

  describe '#include?' do
    it 'checks inclusion in the Redis set' do
      cache.write(:foo, ['value'])

      expect(cache.include?(:foo, 'value')).to be(true)
      expect(cache.include?(:foo, 'bar')).to be(false)
    end
  end

  describe '#try_include?' do
    it 'checks existence of the redis set and inclusion' do
      expect(cache.try_include?(:foo, 'value')).to eq([false, false])

      cache.write(:foo, ['value'])

      expect(cache.try_include?(:foo, 'value')).to eq([true, true])
      expect(cache.try_include?(:foo, 'bar')).to eq([false, true])
    end
  end
end
