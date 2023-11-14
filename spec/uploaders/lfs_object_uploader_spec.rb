# frozen_string_literal: true

require 'spec_helper'

RSpec.describe LfsObjectUploader do
  let(:lfs_object) { create(:lfs_object, :with_file) }
  let(:uploader) { described_class.new(lfs_object, :file) }
  let(:path) { Gitlab.config.lfs.storage_path }

  subject { uploader }

  it_behaves_like "builds correct paths",
    store_dir: %r[\h{2}/\h{2}],
    cache_dir: %r{/lfs-objects/tmp/cache},
    work_dir: %r{/lfs-objects/tmp/work}

  context "object store is REMOTE" do
    before do
      stub_lfs_object_storage
    end

    include_context 'with storage', described_class::Store::REMOTE

    it_behaves_like "builds correct paths",
      store_dir: %r[\h{2}/\h{2}]
  end

  describe 'remote file' do
    let(:lfs_object) { create(:lfs_object, :object_storage, :with_file) }

    context 'with object storage enabled' do
      before do
        stub_lfs_object_storage
      end

      it 'can store file remotely' do
        lfs_object

        expect(lfs_object.file_store).to eq(described_class::Store::REMOTE)
        expect(lfs_object.file.path).not_to be_blank
      end
    end
  end
end
