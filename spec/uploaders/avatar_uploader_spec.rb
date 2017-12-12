require 'spec_helper'

describe AvatarUploader do
  let(:model) { build_stubbed(:user) }
  let(:uploader) { described_class.new(model, :avatar) }
  let(:upload) { create(:upload, model: model) }

  subject { uploader }

  it_behaves_like 'builds correct paths',
                  store_dir: %r[uploads/-/system/user/avatar/],
                  upload_path: %r[uploads/-/system/user/avatar/],
                  absolute_path: %r[#{CarrierWave.root}/uploads/-/system/user/avatar/]

  describe '#move_to_cache' do
    it 'is false' do
      expect(uploader.move_to_cache).to eq(false)
    end
  end

  describe '#move_to_store' do
    it 'is false' do
      expect(uploader.move_to_store).to eq(false)
    end
  end

  # EE-specific
  context "object_store is REMOTE" do
    before do
      stub_uploads_object_storage
    end

    include_context 'with storage', described_class::Store::REMOTE

    it_behaves_like 'builds correct paths',
                    store_dir: %r[user/avatar/],
                    upload_path: %r[user/avatar/]
  end
end
