# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::RepositoryCacheAdapter do
  let(:project) { create(:project, :repository) }
  let(:repository) { project.repository }
  let(:cache) { repository.send(:cache) }
  let(:redis_set_cache) { repository.send(:redis_set_cache) }
  let(:redis_hash_cache) { repository.send(:redis_hash_cache) }

  describe '.cache_method_output_as_redis_set', :clean_gitlab_redis_cache, :aggregate_failures do
    let(:klass) do
      Class.new do
        include Gitlab::RepositoryCacheAdapter # can't use described_class here

        def letters
          %w[b a c]
        end
        cache_method_as_redis_set(:letters)

        def redis_set_cache
          @redis_set_cache ||= Gitlab::RepositorySetCache.new(self)
        end

        def full_path
          'foo/bar'
        end

        def project; end

        def cached_methods
          [:letters]
        end

        def exists?
          true
        end
      end
    end

    let(:fake_repository) { klass.new }
    let(:redis_set_cache) { fake_repository.redis_set_cache }

    context 'with an existing repository' do
      it 'caches the output, sorting the results' do
        expect(fake_repository).to receive(:_uncached_letters).once.and_call_original

        2.times do
          expect(fake_repository.letters).to eq(%w[a b c])
        end

        expect(redis_set_cache.exist?(:letters)).to eq(true)
        expect(fake_repository.instance_variable_get(:@letters)).to eq(%w[a b c])
      end

      context 'membership checks' do
        context 'when the cache key does not exist' do
          it 'calls the original method and populates the cache' do
            expect(redis_set_cache.exist?(:letters)).to eq(false)
            expect(fake_repository).to receive(:_uncached_letters).once.and_call_original

            # This populates the cache and memoizes the full result
            expect(fake_repository.letters_include?('a')).to eq(true)
            expect(fake_repository.letters_include?('d')).to eq(false)
            expect(redis_set_cache.exist?(:letters)).to eq(true)
          end
        end

        context 'when the cache key exists' do
          before do
            redis_set_cache.write(:letters, %w[b a c])
          end

          it 'calls #try_include? on the set cache' do
            expect(redis_set_cache).to receive(:try_include?).with(:letters, 'a').and_call_original
            expect(redis_set_cache).to receive(:try_include?).with(:letters, 'd').and_call_original

            expect(fake_repository.letters_include?('a')).to eq(true)
            expect(fake_repository.letters_include?('d')).to eq(false)
          end

          it 'memoizes the result' do
            expect(redis_set_cache).to receive(:try_include?).once.and_call_original

            expect(fake_repository.letters_include?('a')).to eq(true)
            expect(fake_repository.letters_include?('a')).to eq(true)

            expect(redis_set_cache).to receive(:try_include?).once.and_call_original

            expect(fake_repository.letters_include?('d')).to eq(false)
            expect(fake_repository.letters_include?('d')).to eq(false)
          end
        end
      end
    end
  end

  describe '#cache_method_output', :use_clean_rails_memory_store_caching do
    let(:fallback) { 10 }

    context 'with a non-existing repository' do
      let(:project) { create(:project) } # No repository

      subject do
        repository.cache_method_output(:cats, fallback: fallback) do
          repository.cats_call_stub
        end
      end

      it 'returns the fallback value' do
        expect(subject).to eq(fallback)
      end

      it 'avoids calling the original method' do
        expect(repository).not_to receive(:cats_call_stub)

        subject
      end
    end

    context 'with a method throwing a non-existing-repository error' do
      subject do
        repository.cache_method_output(:cats, fallback: fallback) do
          raise Gitlab::Git::Repository::NoRepository
        end
      end

      it 'returns the fallback value' do
        expect(subject).to eq(fallback)
      end

      it 'does not cache the data' do
        subject

        expect(repository.instance_variable_defined?(:@cats)).to eq(false)
        expect(cache.exist?(:cats)).to eq(false)
      end
    end

    context 'with an existing repository' do
      it 'caches the output' do
        object = double

        expect(object).to receive(:number).once.and_return(10)

        2.times do
          val = repository.cache_method_output(:cats) { object.number }

          expect(val).to eq(10)
        end

        expect(repository.send(:cache).exist?(:cats)).to eq(true)
        expect(repository.instance_variable_get(:@cats)).to eq(10)
      end
    end
  end

  describe '#cache_method_output_asymmetrically', :use_clean_rails_memory_store_caching, :request_store do
    let(:request_store_cache) { repository.send(:request_store_cache) }

    context 'with a non-existing repository' do
      let(:project) { create(:project) } # No repository
      let(:object) { double }

      subject do
        repository.cache_method_output_asymmetrically(:cats) do
          object.cats_call_stub
        end
      end

      it 'returns the output of the original method' do
        expect(object).to receive(:cats_call_stub).and_return('output')

        expect(subject).to eq('output')
      end
    end

    context 'with a method throwing a non-existing-repository error' do
      subject do
        repository.cache_method_output_asymmetrically(:cats) do
          raise Gitlab::Git::Repository::NoRepository
        end
      end

      it 'returns nil' do
        expect(subject).to eq(nil)
      end

      it 'does not cache the data' do
        subject

        expect(repository.instance_variable_defined?(:@cats)).to eq(false)
        expect(cache.exist?(:cats)).to eq(false)
      end
    end

    context 'with an existing repository' do
      let(:object) { double }

      context 'when it returns truthy' do
        before do
          expect(object).to receive(:cats).once.and_return('truthy output')
        end

        it 'caches the output in RequestStore' do
          expect do
            repository.cache_method_output_asymmetrically(:cats) { object.cats }
          end.to change { request_store_cache.read(:cats) }.from(nil).to('truthy output')
        end

        it 'caches the output in RepositoryCache' do
          expect do
            repository.cache_method_output_asymmetrically(:cats) { object.cats }
          end.to change { cache.read(:cats) }.from(nil).to('truthy output')
        end
      end

      context 'when it returns false' do
        before do
          expect(object).to receive(:cats).once.and_return(false)
        end

        it 'caches the output in RequestStore' do
          expect do
            repository.cache_method_output_asymmetrically(:cats) { object.cats }
          end.to change { request_store_cache.read(:cats) }.from(nil).to(false)
        end

        it 'does NOT cache the output in RepositoryCache' do
          expect do
            repository.cache_method_output_asymmetrically(:cats) { object.cats }
          end.not_to change { cache.read(:cats) }.from(nil)
        end
      end
    end
  end

  describe '#memoize_method_output' do
    let(:fallback) { 10 }

    context 'with a non-existing repository' do
      let(:project) { create(:project) } # No repository

      subject do
        repository.memoize_method_output(:cats, fallback: fallback) do
          repository.cats_call_stub
        end
      end

      it 'returns the fallback value' do
        expect(subject).to eq(fallback)
      end

      it 'avoids calling the original method' do
        expect(repository).not_to receive(:cats_call_stub)

        subject
      end

      it 'does not set the instance variable' do
        subject

        expect(repository.instance_variable_defined?(:@cats)).to eq(false)
      end
    end

    context 'with a method throwing a non-existing-repository error' do
      subject do
        repository.memoize_method_output(:cats, fallback: fallback) do
          raise Gitlab::Git::Repository::NoRepository
        end
      end

      it 'returns the fallback value' do
        expect(subject).to eq(fallback)
      end

      it 'does not set the instance variable' do
        subject

        expect(repository.instance_variable_defined?(:@cats)).to eq(false)
      end
    end

    context 'with an existing repository' do
      it 'sets the instance variable' do
        repository.memoize_method_output(:cats, fallback: fallback) do
          'block output'
        end

        expect(repository.instance_variable_get(:@cats)).to eq('block output')
      end
    end
  end

  describe '#expire_method_caches' do
    it 'expires the caches of the given methods' do
      expect(cache).to receive(:expire).with(:branch_names)
      expect(redis_set_cache).to receive(:expire).with(:branch_names)
      expect(redis_hash_cache).to receive(:delete).with(:branch_names)

      repository.expire_method_caches(%i[branch_names])
    end

    it 'does not expire caches for non-existent methods' do
      expect(cache).not_to receive(:expire).with(:nonexistent)
      expect(Gitlab::AppLogger).to(
        receive(:error).with("Requested to expire non-existent method 'nonexistent' for Repository"))

      repository.expire_method_caches(%i[nonexistent])
    end
  end
end
