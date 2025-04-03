# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AttachmentUploader do
  let(:appearance) { create(:appearance, :with_logo) }
  let(:uploader) { appearance.logo }
  let(:upload) { create(:upload, :attachment_upload, model: uploader.model) }

  subject { uploader }

  it_behaves_like 'builds correct paths',
    store_dir: %r{uploads/-/system/appearance/logo/},
    upload_path: %r{uploads/-/system/appearance/logo/},
    absolute_path: %r{#{CarrierWave.root}/uploads/-/system/appearance/logo/}

  context "object_store is REMOTE" do
    before do
      stub_uploads_object_storage
    end

    include_context 'with storage', described_class::Store::REMOTE

    it_behaves_like 'builds correct paths',
      store_dir: %r{appearance/logo/},
      upload_path: %r{appearance/logo/}
  end

  describe "#migrate!" do
    before do
      uploader.store!(fixture_file_upload(File.join('spec/fixtures/doc_sample.txt')))
      stub_uploads_object_storage
    end

    it_behaves_like "migrates", to_store: described_class::Store::REMOTE
    it_behaves_like "migrates", from_store: described_class::Store::REMOTE, to_store: described_class::Store::LOCAL
  end
end
