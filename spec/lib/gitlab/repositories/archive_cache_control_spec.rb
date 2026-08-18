# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Repositories::ArchiveCacheControl, feature_category: :source_code_management do
  let(:project) { build_stubbed(:project, :public) }
  let(:commit_id) { 'ddd0f15ae83993f5cb66a927a28673882e99100b' }
  let(:metadata) { { 'CommitId' => commit_id, 'ArchivePath' => "#{project.path}-master-#{commit_id}.tar.gz" } }
  let(:ref) { 'master' }

  subject(:cache) { described_class.new(project, ref: ref, metadata: metadata) }

  describe '#max_age' do
    context 'when the ref is a moving reference (branch or tag)' do
      it 'caches for the mutable archive cache time' do
        expect(cache.max_age).to eq(Repository::ARCHIVE_CACHE_TIME)
      end
    end

    context 'when the ref is the commit SHA' do
      let(:ref) { commit_id }

      it 'caches for the immutable archive cache time' do
        expect(cache.max_age).to eq(Repository::ARCHIVE_CACHE_TIME_IMMUTABLE)
      end
    end
  end

  describe '#public?' do
    context 'when an anonymous user can download the code' do
      it { expect(cache.public?).to be(true) }
    end

    context 'when an anonymous user cannot download the code' do
      let(:project) { build_stubbed(:project, :private) }

      it { expect(cache.public?).to be(false) }
    end
  end

  describe '#etag_components' do
    it 'is the commit id and archive path by default' do
      expect(cache.etag_components).to eq([commit_id, metadata['ArchivePath']])
    end

    context 'when LFS blobs are excluded' do
      subject(:cache) { described_class.new(project, ref: ref, metadata: metadata, include_lfs_blobs: false) }

      it 'includes the flag so the ETag differs from the default archive' do
        expect(cache.etag_components).to eq([commit_id, metadata['ArchivePath'], false])
      end
    end

    context 'when LFS blobs are explicitly included' do
      subject(:cache) { described_class.new(project, ref: ref, metadata: metadata, include_lfs_blobs: true) }

      it 'matches the default archive since true is the default' do
        expect(cache.etag_components).to eq([commit_id, metadata['ArchivePath']])
      end
    end

    context 'when paths are excluded' do
      subject(:cache) { described_class.new(project, ref: ref, metadata: metadata, exclude_paths: %w[lib test]) }

      it 'includes the paths so the ETag differs from the default archive' do
        expect(cache.etag_components).to eq([commit_id, metadata['ArchivePath'], %w[lib test]])
      end
    end

    context 'when LFS is excluded and paths are excluded' do
      subject(:cache) do
        described_class.new(project, ref: ref, metadata: metadata, include_lfs_blobs: false, exclude_paths: %w[lib])
      end

      it 'includes both so the ETag differs from either alone' do
        expect(cache.etag_components).to eq([commit_id, metadata['ArchivePath'], false, %w[lib]])
      end
    end
  end

  describe '#cache_control' do
    it 'marks public projects as shared-cacheable' do
      expect(cache.cache_control).to eq(
        'max-age=60, public, must-revalidate, stale-while-revalidate=60, stale-if-error=300, s-maxage=60'
      )
    end

    context 'when an anonymous user cannot download the code' do
      let(:project) { build_stubbed(:project, :private) }

      it 'marks the response as private' do
        expect(cache.cache_control).to eq(
          'max-age=60, private, must-revalidate, stale-while-revalidate=60, stale-if-error=300, s-maxage=60'
        )
      end
    end

    context 'when the ref is the commit SHA' do
      let(:ref) { commit_id }

      it 'uses the immutable max-age' do
        expect(cache.cache_control).to start_with('max-age=3600, public')
      end
    end
  end

  describe '#etag' do
    it 'matches the strong ETag Rails generates via fresh_when(strong_etag:)' do
      # ActionDispatch::Response#strong_etag= is what fresh_when(strong_etag:)
      # uses under the hood, so this verifies the web/API responses validate
      # identically rather than re-deriving the value from the implementation.
      rails_response = ActionDispatch::Response.new
      rails_response.strong_etag = cache.etag_components

      expect(cache.etag).to eq(rails_response.get_header('ETag'))
    end
  end
end
