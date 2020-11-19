# frozen_string_literal: true
require 'spec_helper'

RSpec.describe DependencyProxy::FileUploader do
  let(:blob) { create(:dependency_proxy_blob) }
  let(:uploader) { described_class.new(blob, :file) }
  let(:path) { Gitlab.config.dependency_proxy.storage_path }

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
