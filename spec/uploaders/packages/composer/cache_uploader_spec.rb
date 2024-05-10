# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Packages::Composer::CacheUploader, feature_category: :package_registry do
  let_it_be(:cache_file) { create(:composer_cache_file) }
  let(:uploader) { described_class.new(cache_file, :file) }
  let(:path) { Gitlab.config.packages.storage_path }

  subject { uploader }

  it { is_expected.to include_module(Packages::GcsSignedUrlMetadata) }

  it_behaves_like "builds correct paths",
    store_dir: %r[^\h{2}/\h{2}/\h{64}/packages/composer_cache/\d+$],
    cache_dir: %r{/packages/tmp/cache},
    work_dir: %r{/packages/tmp/work}

  context 'object store is remote' do
    before do
      stub_composer_cache_object_storage
    end

    include_context 'with storage', described_class::Store::REMOTE

    it_behaves_like "builds correct paths",
      store_dir: %r[^\h{2}/\h{2}/\h{64}/packages/composer_cache/\d+$]
  end

  describe 'remote file' do
    let(:cache_file) { create(:composer_cache_file, :object_storage) }

    context 'with object storage enabled' do
      before do
        stub_composer_cache_object_storage
      end

      it 'can store file remotely' do
        expect(cache_file.file_store).to eq(described_class::Store::REMOTE)
        expect(cache_file.file.path).not_to be_blank
      end

      it_behaves_like 'augmenting GCS signed URL with metadata' do
        let(:has_project?) { false }
      end
    end
  end
end
