# frozen_string_literal: true

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

  context "object_store is REMOTE" do
    before do
      stub_uploads_object_storage
    end

    include_context 'with storage', described_class::Store::REMOTE

    it_behaves_like 'builds correct paths',
                    store_dir: %r[user/avatar/],
                    upload_path: %r[user/avatar/]
  end

  context "with a file" do
    let(:project) { create(:project, :with_avatar) }
    let(:uploader) { project.avatar }
    let(:upload) { uploader.upload }

    before do
      stub_uploads_object_storage
    end

    it_behaves_like "migrates", to_store: described_class::Store::REMOTE
    it_behaves_like "migrates", from_store: described_class::Store::REMOTE, to_store: described_class::Store::LOCAL

    it 'sets the right absolute path' do
      storage_path = Gitlab.config.uploads.storage_path
      absolute_path = File.join(storage_path, upload.path)

      expect(uploader.absolute_path.scan(storage_path).size).to eq(1)
      expect(uploader.absolute_path).to eq(absolute_path)
    end
  end

  context 'upload type check' do
    AvatarUploader::SAFE_IMAGE_EXT.each do |ext|
      context "#{ext} extension" do
        it_behaves_like 'type checked uploads', filenames: "image.#{ext}"
      end
    end

    context 'skip image/svg+xml integrity check' do
      it_behaves_like 'skipped type checked uploads', filenames: 'image.svg'
    end
  end
end
