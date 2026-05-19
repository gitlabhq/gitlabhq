# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Config::External::CachedContentFetcher, feature_category: :pipeline_composition do
  include RepoHelpers

  let_it_be(:project) { create(:project, :repository) }
  let(:cache_enabled) { true }
  let(:fetcher) { described_class.new(project: project, cache_enabled: cache_enabled) }
  let(:file1_content) { 'test: { script: echo hello }' }
  let(:file2_content) { 'build: { script: echo world }' }
  let(:file1_path) { 'config/ci1.yml' }
  let(:file2_path) { 'config/ci2.yml' }

  describe '#fetch_batch', :clean_gitlab_redis_repository_cache do
    around do |example|
      create_and_delete_files(project, { file1_path => file1_content, file2_path => file2_content }) do
        example.run
      end
    end

    let(:sha) { project.commit.sha }
    let(:cache_key1) { 'ci_test:v1:1:sha1:path1' }
    let(:cache_key2) { 'ci_test:v1:1:sha1:path2' }
    let(:items) { [[[sha, file1_path], cache_key1], [[sha, file2_path], cache_key2]] }

    context 'when cache is enabled' do
      it 'fetches content from repository' do
        result = fetcher.fetch_batch(items)

        expect(result).to eq({
          [sha, file1_path] => file1_content,
          [sha, file2_path] => file2_content
        })
      end

      it 'writes fetched content to cache' do
        cache_store = Gitlab::Redis::RepositoryCache.cache_store

        expect(cache_store.read(cache_key1)).to be_nil
        expect(cache_store.read(cache_key2)).to be_nil

        fetcher.fetch_batch(items)

        expect(cache_store.read(cache_key1)).to eq(file1_content)
        expect(cache_store.read(cache_key2)).to eq(file2_content)
      end

      it 'returns cached content on subsequent calls' do
        first_result = fetcher.fetch_batch(items)

        expect(project.repository).not_to receive(:blobs_at)

        second_result = fetcher.fetch_batch(items)

        expect(second_result).to eq(first_result)
      end

      it 'sets cache expiry to 4 hours' do
        fetcher.fetch_batch(items)

        Gitlab::Redis::RepositoryCache.with do |redis|
          ttl1 = redis.ttl("cache:gitlab:#{cache_key1}")
          ttl2 = redis.ttl("cache:gitlab:#{cache_key2}")

          expect(ttl1).to be_within(60).of(4.hours.to_i)
          expect(ttl2).to be_within(60).of(4.hours.to_i)
        end
      end

      context 'when some items are already cached' do
        before do
          cache_store = Gitlab::Redis::RepositoryCache.cache_store
          cache_store.write(cache_key1, file1_content)
        end

        it 'returns cached content for cached items and fetches uncached items' do
          result = fetcher.fetch_batch(items)

          expect(result).to eq({
            [sha, file1_path] => file1_content,
            [sha, file2_path] => file2_content
          })
        end

        it 'only fetches uncached items from repository' do
          expect(project.repository).to receive(:blobs_at).once.and_call_original

          result = fetcher.fetch_batch(items)

          blobs_fetched = result.keys
          expect(blobs_fetched).to include([sha, file2_path])
        end
      end

      context 'when file does not exist in repository' do
        let(:missing_path) { 'does/not/exist.yml' }
        let(:cache_key3) { 'ci_test:v1:1:sha1:missing' }
        let(:items) { [[[sha, file1_path], cache_key1], [[sha, missing_path], cache_key3]] }

        it 'does not include missing files in results' do
          result = fetcher.fetch_batch(items)

          expect(result).to eq({
            [sha, file1_path] => file1_content
          })
          expect(result).not_to have_key([sha, missing_path])
        end

        it 'does not cache nil values' do
          cache_store = Gitlab::Redis::RepositoryCache.cache_store

          fetcher.fetch_batch(items)

          expect(cache_store.read(cache_key3)).to be_nil
        end
      end
    end

    context 'when cache is disabled' do
      let(:cache_enabled) { false }

      it 'fetches content from repository' do
        result = fetcher.fetch_batch(items)

        expect(result).to eq({
          [sha, file1_path] => file1_content,
          [sha, file2_path] => file2_content
        })
      end

      it 'does not write to cache' do
        cache_store = Gitlab::Redis::RepositoryCache.cache_store

        fetcher.fetch_batch(items)

        expect(cache_store.read(cache_key1)).to be_nil
        expect(cache_store.read(cache_key2)).to be_nil
      end

      it 'does not read from cache' do
        cache_store = Gitlab::Redis::RepositoryCache.cache_store
        cache_store.write(cache_key1, 'cached value')

        result = fetcher.fetch_batch(items)

        expect(result[[sha, file1_path]]).to eq(file1_content)
        expect(result[[sha, file1_path]]).not_to eq('cached value')
      end

      it 'fetches from repository on every call' do
        fetcher.fetch_batch(items)

        expect(project.repository).to receive(:blobs_at).once.and_call_original

        fetcher.fetch_batch(items)
      end
    end

    context 'with empty items array' do
      let(:items) { [] }

      it 'returns empty hash' do
        result = fetcher.fetch_batch(items)

        expect(result).to eq({})
      end

      it 'does not call repository' do
        expect(project.repository).not_to receive(:blobs_at)

        fetcher.fetch_batch(items)
      end
    end

    context 'with multiple items from same SHA' do
      it 'batches all items in single Gitaly call' do
        expect(project.repository).to receive(:blobs_at).once.and_call_original

        result = fetcher.fetch_batch(items)

        expect(result.keys.size).to eq(2)
        expect(result).to include([sha, file1_path], [sha, file2_path])
      end
    end

    context 'with items from different SHAs' do
      let(:old_sha) { project.repository.commit('HEAD~1').sha }
      let(:new_sha) { sha }
      let(:items) { [[[old_sha, file1_path], cache_key1], [[new_sha, file2_path], cache_key2]] }

      it 'handles mixed SHAs in single batch' do
        expect(project.repository).to receive(:blobs_at).once.and_call_original

        result = fetcher.fetch_batch(items)

        expect(result.keys).to contain_exactly([old_sha, file1_path], [new_sha, file2_path])
      end
    end
  end

  describe '#read_cache', :clean_gitlab_redis_repository_cache do
    let(:cache_key) { 'ci_test:v1:1:abc123:config/ci.yml' }

    context 'when cache is enabled' do
      it 'returns nil when cache is empty' do
        expect(fetcher.read_cache(cache_key)).to be_nil
      end

      it 'returns cached content when cache has data' do
        cache_store = Gitlab::Redis::RepositoryCache.cache_store
        cache_store.write(cache_key, 'cached content')

        expect(fetcher.read_cache(cache_key)).to eq('cached content')
      end
    end

    context 'when cache is disabled' do
      let(:cache_enabled) { false }

      it 'returns nil without reading from cache' do
        cache_store = Gitlab::Redis::RepositoryCache.cache_store
        cache_store.write(cache_key, 'cached content')

        expect(cache_store).not_to receive(:read)
        expect(fetcher.read_cache(cache_key)).to be_nil
      end
    end
  end

  describe 'CACHE_EXPIRY' do
    it 'is set to 4 hours' do
      expect(described_class::CACHE_EXPIRY).to eq(4.hours)
    end
  end
end
