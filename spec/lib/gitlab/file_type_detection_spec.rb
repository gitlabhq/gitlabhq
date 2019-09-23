# frozen_string_literal: true
require 'spec_helper'

describe Gitlab::FileTypeDetection do
  context 'when class is an uploader' do
    shared_examples '#image? for an uploader' do
      it 'returns true for an image file' do
        uploader.store!(upload_fixture('dk.png'))

        expect(uploader).to be_image
      end

      it 'returns false if filename has a dangerous image extension' do
        uploader.store!(upload_fixture('unsanitized.svg'))

        expect(uploader).to be_dangerous_image
        expect(uploader).not_to be_image
      end

      it 'returns false for a video file' do
        uploader.store!(upload_fixture('video_sample.mp4'))

        expect(uploader).not_to be_image
      end

      it 'returns false if filename is blank' do
        uploader.store!(upload_fixture('dk.png'))

        allow(uploader).to receive(:filename).and_return(nil)

        expect(uploader).not_to be_image
      end
    end

    shared_examples '#video? for an uploader' do
      it 'returns true for a video file' do
        uploader.store!(upload_fixture('video_sample.mp4'))

        expect(uploader).to be_video
      end

      it 'returns false for an image file' do
        uploader.store!(upload_fixture('dk.png'))

        expect(uploader).not_to be_video
      end

      it 'returns false if filename is blank' do
        uploader.store!(upload_fixture('dk.png'))

        allow(uploader).to receive(:filename).and_return(nil)

        expect(uploader).not_to be_video
      end
    end

    shared_examples '#dangerous_image? for an uploader' do
      it 'returns true if filename has a dangerous extension' do
        uploader.store!(upload_fixture('unsanitized.svg'))

        expect(uploader).to be_dangerous_image
      end

      it 'returns false for an image file' do
        uploader.store!(upload_fixture('dk.png'))

        expect(uploader).not_to be_dangerous_image
      end

      it 'returns false for a video file' do
        uploader.store!(upload_fixture('video_sample.mp4'))

        expect(uploader).not_to be_dangerous_image
      end

      it 'returns false if filename is blank' do
        uploader.store!(upload_fixture('dk.png'))

        allow(uploader).to receive(:filename).and_return(nil)

        expect(uploader).not_to be_dangerous_image
      end
    end

    shared_examples '#dangerous_video? for an uploader' do
      it 'returns false for a safe video file' do
        uploader.store!(upload_fixture('video_sample.mp4'))

        expect(uploader).not_to be_dangerous_video
      end

      it 'returns false if filename is a dangerous image extension' do
        uploader.store!(upload_fixture('unsanitized.svg'))

        expect(uploader).not_to be_dangerous_video
      end

      it 'returns false for an image file' do
        uploader.store!(upload_fixture('dk.png'))

        expect(uploader).not_to be_dangerous_video
      end

      it 'returns false if filename is blank' do
        uploader.store!(upload_fixture('dk.png'))

        allow(uploader).to receive(:filename).and_return(nil)

        expect(uploader).not_to be_dangerous_video
      end
    end

    let(:uploader) do
      example_uploader = Class.new(CarrierWave::Uploader::Base) do
        include Gitlab::FileTypeDetection

        storage :file
      end

      example_uploader.new
    end

    def upload_fixture(filename)
      fixture_file_upload(File.join('spec', 'fixtures', filename))
    end

    describe '#image?' do
      include_examples '#image? for an uploader'
    end

    describe '#video?' do
      include_examples '#video? for an uploader'
    end

    describe '#image_or_video?' do
      include_examples '#image? for an uploader'
      include_examples '#video? for an uploader'
    end

    describe '#dangerous_image?' do
      include_examples '#dangerous_image? for an uploader'
    end

    describe '#dangerous_video?' do
      include_examples '#dangerous_video? for an uploader'
    end

    describe '#dangerous_image_or_video?' do
      include_examples '#dangerous_image? for an uploader'
      include_examples '#dangerous_video? for an uploader'
    end
  end

  context 'when class is a regular class' do
    shared_examples '#image? for a regular class' do
      it 'returns true for an image file' do
        allow(custom_class).to receive(:filename).and_return('dk.png')

        expect(custom_class).to be_image
      end

      it 'returns false if file has a dangerous image extension' do
        allow(custom_class).to receive(:filename).and_return('unsanitized.svg')

        expect(custom_class).to be_dangerous_image
        expect(custom_class).not_to be_image
      end

      it 'returns false for any non image file' do
        allow(custom_class).to receive(:filename).and_return('video_sample.mp4')

        expect(custom_class).not_to be_image
      end

      it 'returns false if filename is blank' do
        allow(custom_class).to receive(:filename).and_return(nil)

        expect(custom_class).not_to be_image
      end
    end

    shared_examples '#video? for a regular class' do
      it 'returns true for a video file' do
        allow(custom_class).to receive(:filename).and_return('video_sample.mp4')

        expect(custom_class).to be_video
      end

      it 'returns false for any non-video file' do
        allow(custom_class).to receive(:filename).and_return('dk.png')

        expect(custom_class).not_to be_video
      end

      it 'returns false if file has a dangerous image extension' do
        allow(custom_class).to receive(:filename).and_return('unsanitized.svg')

        expect(custom_class).to be_dangerous_image
        expect(custom_class).not_to be_video
      end

      it 'returns false if filename is blank' do
        allow(custom_class).to receive(:filename).and_return(nil)

        expect(custom_class).not_to be_video
      end
    end

    shared_examples '#dangerous_image? for a regular class' do
      it 'returns true if file has a dangerous image extension' do
        allow(custom_class).to receive(:filename).and_return('unsanitized.svg')

        expect(custom_class).to be_dangerous_image
      end

      it 'returns false for an image file' do
        allow(custom_class).to receive(:filename).and_return('dk.png')

        expect(custom_class).not_to be_dangerous_image
      end

      it 'returns false for any non image file' do
        allow(custom_class).to receive(:filename).and_return('video_sample.mp4')

        expect(custom_class).not_to be_dangerous_image
      end

      it 'returns false if filename is blank' do
        allow(custom_class).to receive(:filename).and_return(nil)

        expect(custom_class).not_to be_dangerous_image
      end
    end

    shared_examples '#dangerous_video? for a regular class' do
      it 'returns false for a safe video file' do
        allow(custom_class).to receive(:filename).and_return('video_sample.mp4')

        expect(custom_class).not_to be_dangerous_video
      end

      it 'returns false for an image file' do
        allow(custom_class).to receive(:filename).and_return('dk.png')

        expect(custom_class).not_to be_dangerous_video
      end

      it 'returns false if file has a dangerous image extension' do
        allow(custom_class).to receive(:filename).and_return('unsanitized.svg')

        expect(custom_class).not_to be_dangerous_video
      end

      it 'returns false if filename is blank' do
        allow(custom_class).to receive(:filename).and_return(nil)

        expect(custom_class).not_to be_dangerous_video
      end
    end

    let(:custom_class) do
      custom_class = Class.new do
        include Gitlab::FileTypeDetection
      end

      custom_class.new
    end

    describe '#image?' do
      include_examples '#image? for a regular class'
    end

    describe '#video?' do
      include_examples '#video? for a regular class'
    end

    describe '#image_or_video?' do
      include_examples '#image? for a regular class'
      include_examples '#video? for a regular class'
    end

    describe '#dangerous_image?' do
      include_examples '#dangerous_image? for a regular class'
    end

    describe '#dangerous_video?' do
      include_examples '#dangerous_video? for a regular class'
    end

    describe '#dangerous_image_or_video?' do
      include_examples '#dangerous_image? for a regular class'
      include_examples '#dangerous_video? for a regular class'
    end
  end
end
