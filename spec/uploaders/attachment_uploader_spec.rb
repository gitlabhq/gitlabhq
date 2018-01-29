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

  describe '#move_to_cache' do
    it 'is true' do
      expect(uploader.move_to_cache).to eq(true)
    end
  end

  describe '#move_to_store' do
    it 'is true' do
      expect(uploader.move_to_store).to eq(true)
    end
  end
end
