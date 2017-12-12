require 'spec_helper'

describe AttachmentUploader do
  let(:uploader) { described_class.new(build_stubbed(:user), :attachment) }
  let(:upload) { create(:upload, :attachment_upload, model: uploader.model) }

  subject { uploader }

  it_behaves_like 'builds correct paths',
                  store_dir: %r[uploads/-/system/user/attachment/],
                  upload_path: %r[uploads/-/system/user/attachment/],
                  absolute_path: %r[#{CarrierWave.root}/uploads/-/system/user/attachment/]

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

  # EE-specific
  context "object_store is REMOTE" do
    before do
      stub_uploads_object_storage
    end

    include_context 'with storage', described_class::Store::REMOTE

    it_behaves_like 'builds correct paths',
                    store_dir: %r[user/attachment/],
                    upload_path: %r[user/attachment/]
  end
end
