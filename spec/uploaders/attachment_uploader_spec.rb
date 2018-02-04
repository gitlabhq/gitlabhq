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
end
