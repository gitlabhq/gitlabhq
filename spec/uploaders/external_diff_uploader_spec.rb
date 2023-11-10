# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ExternalDiffUploader do
  let(:diff) { create(:merge_request).merge_request_diff }
  let(:path) { Gitlab.config.external_diffs.storage_path }

  subject(:uploader) { described_class.new(diff, :external_diff) }

  it_behaves_like "builds correct paths",
    store_dir: %r{merge_request_diffs/mr-\d+},
    cache_dir: %r{/external-diffs/tmp/cache},
    work_dir: %r{/external-diffs/tmp/work}

  context "object store is REMOTE" do
    before do
      stub_external_diffs_object_storage
    end

    include_context 'with storage', described_class::Store::REMOTE

    it_behaves_like "builds correct paths",
      store_dir: %r{merge_request_diffs/mr-\d+}
  end

  describe 'remote file' do
    context 'with object storage enabled' do
      before do
        stub_external_diffs_setting(enabled: true)
        stub_external_diffs_object_storage

        diff.update!(external_diff_store: described_class::Store::REMOTE)
      end

      it 'can store file remotely' do
        diff

        expect(diff.external_diff_store).to eq(described_class::Store::REMOTE)
        expect(diff.external_diff.path).not_to be_blank
      end
    end
  end
end
