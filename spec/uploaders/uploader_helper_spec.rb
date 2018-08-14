require 'rails_helper'

describe UploaderHelper do
  let(:uploader) do
    example_uploader = Class.new(CarrierWave::Uploader::Base) do
      include UploaderHelper

      storage :file
    end

    example_uploader.new
  end

  def upload_fixture(filename)
    fixture_file_upload(File.join('spec', 'fixtures', filename))
  end

  describe '#image_or_video?' do
    it 'returns true for an image file' do
      uploader.store!(upload_fixture('dk.png'))

      expect(uploader).to be_image_or_video
    end

    it 'it returns true for a video file' do
      uploader.store!(upload_fixture('video_sample.mp4'))

      expect(uploader).to be_image_or_video
    end

    it 'returns false for other extensions' do
      uploader.store!(upload_fixture('doc_sample.txt'))

      expect(uploader).not_to be_image_or_video
    end
  end
end
