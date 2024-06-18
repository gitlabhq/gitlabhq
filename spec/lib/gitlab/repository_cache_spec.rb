# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::RepositoryCache do
  let_it_be(:project) { create(:project) }

  let(:backend) { double('backend').as_null_object }
  let(:repository) { project.repository }
  let(:namespace) { "#{repository.full_path}:#{project.id}" }
  let(:cache) { described_class.new(repository, backend: backend) }

  describe '#cache_key' do
    subject { cache.cache_key(:foo) }

    shared_examples 'cache_key examples' do
      it 'includes the namespace' do
        expect(subject).to eq "foo:#{namespace}"
      end

      context 'with a given namespace' do
        let(:extra_namespace) { 'my:data' }
        let(:cache) do
          described_class.new(repository, extra_namespace: extra_namespace,
            backend: backend)
        end

        it 'includes the full namespace' do
          expect(subject).to eq "foo:#{namespace}:#{extra_namespace}"
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
    it 'expires the given key from the cache' do
      cache.expire(:foo)
      expect(backend).to have_received(:delete).with("foo:#{namespace}")
    end
  end

  describe '#fetch' do
    it 'fetches the given key from the cache' do
      cache.fetch(:bar)
      expect(backend).to have_received(:fetch).with("bar:#{namespace}")
    end

    it 'accepts a block' do
      p = -> {}

      cache.fetch(:baz, &p)
      expect(backend).to have_received(:fetch).with("baz:#{namespace}", &p)
    end
  end

  describe '#write' do
    it 'writes the given key and value to the cache' do
      cache.write(:test, 'test')
      expect(backend).to have_received(:write).with("test:#{namespace}", 'test')
    end

    it 'passes additional options to the backend' do
      cache.write(:test, 'test', expires_in: 10.minutes)
      expect(backend).to have_received(:write).with("test:#{namespace}", 'test', expires_in: 10.minutes)
    end
  end

  describe '#fetch_without_caching_false', :use_clean_rails_memory_store_caching do
    let(:key) { :foo }
    let(:backend) { Rails.cache }

    it 'requires a block' do
      expect do
        cache.fetch_without_caching_false(key)
      end.to raise_error(LocalJumpError)
    end

    context 'when the key does not exist in the cache' do
      context 'when the result of the block is truthy' do
        it 'returns the result of the block' do
          result = cache.fetch_without_caching_false(key) { true }

          expect(result).to be true
        end

        it 'caches the value' do
          expect(backend).to receive(:write).with("#{key}:#{namespace}", true)

          cache.fetch_without_caching_false(key) { true }
        end
      end

      context 'when the result of the block is falsey' do
        let(:p) { -> { false } }

        it 'returns the result of the block' do
          result = cache.fetch_without_caching_false(key, &p)

          expect(result).to be false
        end

        it 'does not cache the value' do
          expect(backend).not_to receive(:write).with("#{key}:#{namespace}", true)

          cache.fetch_without_caching_false(key, &p)
        end
      end
    end

    context 'when the cached value is truthy' do
      before do
        backend.write("#{key}:#{namespace}", true)
      end

      it 'returns the cached value' do
        result = cache.fetch_without_caching_false(key) { 'block result' }

        expect(result).to be true
      end

      it 'does not execute the block' do
        expect do |b|
          cache.fetch_without_caching_false(key, &b)
        end.not_to yield_control
      end

      it 'does not write to the cache' do
        expect(backend).not_to receive(:write)

        cache.fetch_without_caching_false(key) { 'block result' }
      end
    end

    context 'when the cached value is falsey' do
      before do
        backend.write("#{key}:#{namespace}", false)
      end

      it 'returns the result of the block' do
        result = cache.fetch_without_caching_false(key) { 'block result' }

        expect(result).to eq 'block result'
      end

      it 'writes the truthy value to the cache' do
        expect(backend).to receive(:write).with("#{key}:#{namespace}", 'block result')

        cache.fetch_without_caching_false(key) { 'block result' }
      end
    end
  end
end
