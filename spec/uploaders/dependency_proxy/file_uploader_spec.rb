# frozen_string_literal: true
require 'spec_helper'

RSpec.describe DependencyProxy::FileUploader do
  describe 'DependencyProxy::Blob uploader' do
    let_it_be(:blob) { create(:dependency_proxy_blob) }
    let_it_be(:path) { Gitlab.config.dependency_proxy.storage_path }

    let(:uploader) { described_class.new(blob, :file) }

    subject { uploader }

    it_behaves_like "builds correct paths",
                    store_dir: %r[\h{2}/\h{2}],
                    cache_dir: %r[/dependency_proxy/tmp/cache],
                    work_dir: %r[/dependency_proxy/tmp/work]

    context 'object store is remote' do
      before do
        stub_dependency_proxy_object_storage
      end

      include_context 'with storage', described_class::Store::REMOTE

      it_behaves_like "builds correct paths",
                      store_dir: %r[\h{2}/\h{2}]
    end
  end

  describe 'DependencyProxy::Manifest uploader' do
    let_it_be(:manifest) { create(:dependency_proxy_manifest) }
    let_it_be(:initial_content_type) { 'application/json' }
    let_it_be(:fixture_file) { fixture_file_upload('spec/fixtures/dependency_proxy/manifest', initial_content_type) }

    let(:uploader) { described_class.new(manifest, :file) }

    subject { uploader }

    it 'will change upload file content type to match the model content type', :aggregate_failures do
      uploader.cache!(fixture_file)

      expect(uploader.file.content_type).to eq(manifest.content_type)
      expect(uploader.file.content_type).not_to eq(initial_content_type)
    end
  end
end
