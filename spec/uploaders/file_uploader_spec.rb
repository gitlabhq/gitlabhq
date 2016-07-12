require 'spec_helper'

describe FileUploader do
  let(:project) { create(:project) }

  before do
    @previous_enable_processing = FileUploader.enable_processing
    FileUploader.enable_processing = false
    @uploader = FileUploader.new(project)
  end

  after do
    FileUploader.enable_processing = @previous_enable_processing
    @uploader.remove!
  end

  describe '#image_or_video?' do
    context 'given an image file' do
      before do
        @uploader.store!(File.new(Rails.root.join('spec', 'fixtures', 'rails_sample.jpg')))
      end

      it 'detects an image based on file extension' do
        expect(@uploader.image_or_video?).to be true
      end
    end

    context 'given an video file' do
      before do
        video_file = File.new(Rails.root.join('spec', 'fixtures', 'video_sample.mp4'))
        @uploader.store!(video_file)
      end

      it 'detects a video based on file extension' do
        expect(@uploader.image_or_video?).to be true
      end
    end

    it 'does not return image_or_video? for other types' do
      @uploader.store!(File.new(Rails.root.join('spec', 'fixtures', 'doc_sample.txt')))

      expect(@uploader.image_or_video?).to be false
    end
  end
end
