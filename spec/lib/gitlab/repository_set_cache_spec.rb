# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::RepositorySetCache, :clean_gitlab_redis_cache do
  let_it_be(:project) { create(:project) }
  let(:repository) { project.repository }
  let(:namespace) { "#{repository.full_path}:#{project.id}" }
  let(:cache) { described_class.new(repository) }

  describe '#cache_key' do
    subject { cache.cache_key(:foo) }

    shared_examples 'cache_key examples' do
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
      let(:keys) { %w(foo) }

      it { is_expected.to eq(1) }

      it 'deletes the given key from the cache' do
        subject

        expect(cache.read(:foo)).to be_empty
      end
    end

    context 'multiple keys' do
      let(:keys) { %w(foo bar) }

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

    context "unlink isn't supported" do
      before do
        allow_any_instance_of(Redis).to receive(:unlink) { raise ::Redis::CommandError }
      end

      it 'still deletes the given key' do
        expect(cache.expire(:foo)).to eq(1)
        expect(cache.read(:foo)).to be_empty
      end

      it 'logs the failure' do
        expect(Gitlab::ErrorTracking).to receive(:log_exception)

        cache.expire(:foo)
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

  describe '#include?' do
    it 'checks inclusion in the Redis set' do
      cache.write(:foo, ['value'])

      expect(cache.include?(:foo, 'value')).to be(true)
      expect(cache.include?(:foo, 'bar')).to be(false)
    end
  end
end
