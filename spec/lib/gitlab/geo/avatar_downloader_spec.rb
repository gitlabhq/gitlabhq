require 'spec_helper'

describe Gitlab::Geo::AvatarDownloader do
  let(:avatar) { fixture_file_upload(Rails.root + 'spec/fixtures/dk.png', 'image/png') }
  let(:user)   { create(:user, avatar: avatar) }
  let(:upload) { Upload.find_by(model: user, uploader: 'AvatarUploader') }

  context '#download_from_primary' do
    it 'downlods the avatar' do
      allow_any_instance_of(Gitlab::Geo::AvatarTransfer)
        .to receive(:download_from_primary).and_return(100)

      downloader = described_class.new(upload.id)

      expect(downloader.execute).to eq(100)
    end

    it 'returns nil with unknown avatar' do
      downloader = described_class.new(10000)

      expect(downloader).not_to receive(:download_from_primary)
      expect(downloader.execute).to be_nil
    end
  end
end
