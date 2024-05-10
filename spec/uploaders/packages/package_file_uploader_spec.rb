# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Packages::PackageFileUploader, feature_category: :package_registry do
  let_it_be(:package_file) { create(:package_file) }
  let(:uploader) { described_class.new(package_file, :file) }
  let(:path) { Gitlab.config.packages.storage_path }

  subject { uploader }

  it { is_expected.to include_module(Packages::GcsSignedUrlMetadata) }

  it_behaves_like "builds correct paths",
    store_dir: %r[^\h{2}/\h{2}/\h{64}/packages/\d+/files/\d+$],
    cache_dir: %r{/packages/tmp/cache},
    work_dir: %r{/packages/tmp/work}

  context 'object store is remote' do
    before do
      stub_package_file_object_storage
    end

    include_context 'with storage', described_class::Store::REMOTE

    it_behaves_like "builds correct paths",
      store_dir: %r[^\h{2}/\h{2}/\h{64}/packages/\d+/files/\d+$]
  end

  describe 'remote file' do
    let(:package_file) { create(:package_file, :object_storage) }

    context 'with object storage enabled' do
      before do
        stub_package_file_object_storage
      end

      it 'can store file remotely' do
        expect(package_file.file_store).to eq(described_class::Store::REMOTE)
        expect(package_file.file.path).not_to be_blank
      end

      it_behaves_like 'augmenting GCS signed URL with metadata'
    end
  end
end
