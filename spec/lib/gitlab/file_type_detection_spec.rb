# frozen_string_literal: true
require 'rails_helper'

describe Gitlab::FileTypeDetection do
  def upload_fixture(filename)
    fixture_file_upload(File.join('spec', 'fixtures', filename))
  end

  describe '#image_or_video?' do
    context 'when class is an uploader' do
      let(:uploader) do
        example_uploader = Class.new(CarrierWave::Uploader::Base) do
          include Gitlab::FileTypeDetection

          storage :file
        end

        example_uploader.new
      end

      it 'returns true for an image file' do
        uploader.store!(upload_fixture('dk.png'))

        expect(uploader).to be_image_or_video
      end

      it 'returns true for a video file' do
        uploader.store!(upload_fixture('video_sample.mp4'))

        expect(uploader).to be_image_or_video
      end

      it 'returns false for other extensions' do
        uploader.store!(upload_fixture('doc_sample.txt'))

        expect(uploader).not_to be_image_or_video
      end

      it 'returns false if filename is blank' do
        uploader.store!(upload_fixture('dk.png'))

        allow(uploader).to receive(:filename).and_return(nil)

        expect(uploader).not_to be_image_or_video
      end
    end

    context 'when class is a regular class' do
      let(:custom_class) do
        custom_class = Class.new do
          include Gitlab::FileTypeDetection
        end

        custom_class.new
      end

      it 'returns true for an image file' do
        allow(custom_class).to receive(:filename).and_return('dk.png')

        expect(custom_class).to be_image_or_video
      end

      it 'returns true for a video file' do
        allow(custom_class).to receive(:filename).and_return('video_sample.mp4')

        expect(custom_class).to be_image_or_video
      end

      it 'returns false for other extensions' do
        allow(custom_class).to receive(:filename).and_return('doc_sample.txt')

        expect(custom_class).not_to be_image_or_video
      end

      it 'returns false if filename is blank' do
        allow(custom_class).to receive(:filename).and_return(nil)

        expect(custom_class).not_to be_image_or_video
      end
    end
  end
end
