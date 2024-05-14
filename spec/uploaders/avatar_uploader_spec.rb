# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AvatarUploader do
  let(:model) { build_stubbed(:user) }
  let(:uploader) { described_class.new(model, :avatar) }
  let(:upload) { create(:upload, model: model) }

  subject { uploader }

  it_behaves_like 'builds correct paths',
    store_dir: %r{uploads/-/system/user/avatar/},
    upload_path: %r{uploads/-/system/user/avatar/},
    absolute_path: %r{#{CarrierWave.root}/uploads/-/system/user/avatar/}

  context "object_store is REMOTE" do
    before do
      stub_uploads_object_storage
    end

    include_context 'with storage', described_class::Store::REMOTE

    it_behaves_like 'builds correct paths',
      store_dir: %r{user/avatar/},
      upload_path: %r{user/avatar/}
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

    describe "avatar cache" do
      subject(:user) { create(:user) }

      let(:file_path) do
        File.join("spec", "fixtures", "rails_sample.png")
      end

      let(:file) { fixture_file_upload(file_path) }

      it "clears the cache on upload" do
        expect(Gitlab::AvatarCache).to receive(:delete_by_email).with(*user.verified_emails).once

        user.avatar = file
        user.save!
      end

      it "clears the cache on removal" do
        user.avatar = file
        user.save!

        expect(Gitlab::AvatarCache).to receive(:delete_by_email).with(*user.verified_emails).once

        user.avatar.remove!
      end
    end
  end

  context 'accept allowlist file content type' do
    # We need to feed through a valid path, but we force the parsed mime type
    # in a stub below so we can set any path.
    let_it_be(:path) { File.join('spec', 'fixtures', 'video_sample.mp4') }

    where(:mime_type) { described_class::MIME_ALLOWLIST }

    with_them do
      include_context 'force content type detection to mime_type'

      it_behaves_like 'accepted carrierwave upload'
    end
  end

  context 'upload denylisted file content type' do
    let_it_be(:path) { File.join('spec', 'fixtures', 'sanitized.svg') }

    it_behaves_like 'denied carrierwave upload'
  end

  context 'upload misnamed denylisted file content type' do
    let_it_be(:path) { File.join('spec', 'fixtures', 'not_a_png.png') }

    it_behaves_like 'denied carrierwave upload'
  end
end
