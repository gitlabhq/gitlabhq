# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Packages::Composer::CacheUploader do
  let(:cache_file) { create(:composer_cache_file) } # rubocop:disable Rails/SaveBang
  let(:uploader) { described_class.new(cache_file, :file) }
  let(:path) { Gitlab.config.packages.storage_path }

  subject { uploader }

  it_behaves_like "builds correct paths",
                  store_dir: %r[^\h{2}/\h{2}/\h{64}/packages/composer_cache/\d+$],
                  cache_dir: %r[/packages/tmp/cache],
                  work_dir: %r[/packages/tmp/work]

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
        allow(ObjectStorage::BackgroundMoveWorker).to receive(:perform_async)

        cache_file

        expect(cache_file.file_store).to eq(described_class::Store::REMOTE)
        expect(cache_file.file.path).not_to be_blank
      end
    end
  end
end
