require 'spec_helper'

describe AttachmentUploader do
  let(:note) { create(:note, :with_attachment) }
  let(:uploader) { note.attachment }
  let(:upload) { create(:upload, :attachment_upload, model: uploader.model) }

  subject { uploader }

  it_behaves_like 'builds correct paths',
                  store_dir: %r[uploads/-/system/note/attachment/],
                  upload_path: %r[uploads/-/system/note/attachment/],
                  absolute_path: %r[#{CarrierWave.root}/uploads/-/system/note/attachment/]

  context "object_store is REMOTE" do
    before do
      stub_uploads_object_storage
    end

    include_context 'with storage', described_class::Store::REMOTE

    it_behaves_like 'builds correct paths',
                    store_dir: %r[note/attachment/],
                    upload_path: %r[note/attachment/]
  end

  describe "#migrate!" do
    before do
      uploader.store!(fixture_file_upload(Rails.root.join('spec/fixtures/doc_sample.txt')))
      stub_uploads_object_storage
    end

    it_behaves_like "migrates", to_store: described_class::Store::REMOTE
    it_behaves_like "migrates", from_store: described_class::Store::REMOTE, to_store: described_class::Store::LOCAL
  end
end
