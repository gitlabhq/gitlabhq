# frozen_string_literal: true
require 'spec_helper'

describe Gitlab::FileTypeDetection do
  describe '.extension_match?' do
    let(:extensions) { %w[foo bar] }

    it 'returns false when filename is blank' do
      expect(described_class.extension_match?(nil, extensions)).to eq(false)
      expect(described_class.extension_match?('', extensions)).to eq(false)
    end

    it 'returns true when filename matches extensions' do
      expect(described_class.extension_match?('file.foo', extensions)).to eq(true)
      expect(described_class.extension_match?('file.bar', extensions)).to eq(true)
    end

    it 'returns false when filename does not match extensions' do
      expect(described_class.extension_match?('file.baz', extensions)).to eq(false)
    end

    it 'can match case insensitive filenames' do
      expect(described_class.extension_match?('file.FOO', extensions)).to eq(true)
    end

    it 'can match filenames with periods' do
      expect(described_class.extension_match?('my.file.foo', extensions)).to eq(true)
    end

    it 'can match filenames with directories' do
      expect(described_class.extension_match?('my/file.foo', extensions)).to eq(true)
    end
  end
  context 'when class is an uploader' do
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

      it 'returns false for an audio file' do
        uploader.store!(upload_fixture('audio_sample.wav'))

        expect(uploader).not_to be_image
      end

      it 'returns false if filename is blank' do
        uploader.store!(upload_fixture('dk.png'))

        allow(uploader).to receive(:filename).and_return(nil)

        expect(uploader).not_to be_image
      end
    end

    describe '#video?' do
      it 'returns true for a video file' do
        uploader.store!(upload_fixture('video_sample.mp4'))

        expect(uploader).to be_video
      end

      it 'returns false for an image file' do
        uploader.store!(upload_fixture('dk.png'))

        expect(uploader).not_to be_video
      end

      it 'returns false for an audio file' do
        uploader.store!(upload_fixture('audio_sample.wav'))

        expect(uploader).not_to be_video
      end

      it 'returns false if file has a dangerous image extension' do
        uploader.store!(upload_fixture('unsanitized.svg'))

        expect(uploader).to be_dangerous_image
        expect(uploader).not_to be_video
      end

      it 'returns false if filename is blank' do
        uploader.store!(upload_fixture('video_sample.mp4'))

        allow(uploader).to receive(:filename).and_return(nil)

        expect(uploader).not_to be_video
      end
    end

    describe '#audio?' do
      it 'returns true for an audio file' do
        uploader.store!(upload_fixture('audio_sample.wav'))

        expect(uploader).to be_audio
      end

      it 'returns false for an image file' do
        uploader.store!(upload_fixture('dk.png'))

        expect(uploader).not_to be_audio
      end

      it 'returns false for a video file' do
        uploader.store!(upload_fixture('video_sample.mp4'))

        expect(uploader).not_to be_audio
      end

      it 'returns false if file has a dangerous image extension' do
        uploader.store!(upload_fixture('unsanitized.svg'))

        expect(uploader).to be_dangerous_image
        expect(uploader).not_to be_audio
      end

      it 'returns false if filename is blank' do
        uploader.store!(upload_fixture('audio_sample.wav'))

        allow(uploader).to receive(:filename).and_return(nil)

        expect(uploader).not_to be_audio
      end
    end

    describe '#embeddable?' do
      it 'returns true for an image file' do
        uploader.store!(upload_fixture('dk.png'))

        expect(uploader).to be_embeddable
      end

      it 'returns true for a video file' do
        uploader.store!(upload_fixture('video_sample.mp4'))

        expect(uploader).to be_embeddable
      end

      it 'returns true for an audio file' do
        uploader.store!(upload_fixture('audio_sample.wav'))

        expect(uploader).to be_embeddable
      end

      it 'returns false if not an embeddable file' do
        uploader.store!(upload_fixture('doc_sample.txt'))

        expect(uploader).not_to be_embeddable
      end

      it 'returns false if filename has a dangerous image extension' do
        uploader.store!(upload_fixture('unsanitized.svg'))

        expect(uploader).to be_dangerous_image
        expect(uploader).not_to be_embeddable
      end

      it 'returns false if filename is blank' do
        uploader.store!(upload_fixture('dk.png'))

        allow(uploader).to receive(:filename).and_return(nil)

        expect(uploader).not_to be_embeddable
      end
    end

    describe '#dangerous_image?' do
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

      it 'returns false for an audio file' do
        uploader.store!(upload_fixture('audio_sample.wav'))

        expect(uploader).not_to be_dangerous_image
      end

      it 'returns false if filename is blank' do
        uploader.store!(upload_fixture('dk.png'))

        allow(uploader).to receive(:filename).and_return(nil)

        expect(uploader).not_to be_dangerous_image
      end
    end

    describe '#dangerous_video?' do
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

      it 'returns false for an audio file' do
        uploader.store!(upload_fixture('audio_sample.wav'))

        expect(uploader).not_to be_dangerous_video
      end

      it 'returns false if filename is blank' do
        uploader.store!(upload_fixture('dk.png'))

        allow(uploader).to receive(:filename).and_return(nil)

        expect(uploader).not_to be_dangerous_video
      end
    end

    describe '#dangerous_audio?' do
      it 'returns false for a safe audio file' do
        uploader.store!(upload_fixture('audio_sample.wav'))

        expect(uploader).not_to be_dangerous_audio
      end

      it 'returns false if filename is a dangerous image extension' do
        uploader.store!(upload_fixture('unsanitized.svg'))

        expect(uploader).not_to be_dangerous_audio
      end

      it 'returns false for an image file' do
        uploader.store!(upload_fixture('dk.png'))

        expect(uploader).not_to be_dangerous_audio
      end

      it 'returns false for an video file' do
        uploader.store!(upload_fixture('video_sample.mp4'))

        expect(uploader).not_to be_dangerous_audio
      end

      it 'returns false if filename is blank' do
        uploader.store!(upload_fixture('dk.png'))

        allow(uploader).to receive(:filename).and_return(nil)

        expect(uploader).not_to be_dangerous_audio
      end
    end

    describe '#dangerous_embeddable?' do
      it 'returns true if filename has a dangerous image extension' do
        uploader.store!(upload_fixture('unsanitized.svg'))

        expect(uploader).to be_dangerous_embeddable
      end

      it 'returns false for an image file' do
        uploader.store!(upload_fixture('dk.png'))

        expect(uploader).not_to be_dangerous_embeddable
      end

      it 'returns false for a video file' do
        uploader.store!(upload_fixture('video_sample.mp4'))

        expect(uploader).not_to be_dangerous_embeddable
      end

      it 'returns false for an audio file' do
        uploader.store!(upload_fixture('audio_sample.wav'))

        expect(uploader).not_to be_dangerous_embeddable
      end

      it 'returns false for a non-embeddable file' do
        uploader.store!(upload_fixture('doc_sample.txt'))

        expect(uploader).not_to be_dangerous_embeddable
      end

      it 'returns false if filename is blank' do
        uploader.store!(upload_fixture('dk.png'))

        allow(uploader).to receive(:filename).and_return(nil)

        expect(uploader).not_to be_dangerous_embeddable
      end
    end
  end

  context 'when class is a regular class' do
    let(:custom_class) do
      custom_class = Class.new do
        include Gitlab::FileTypeDetection
      end

      custom_class.new
    end

    describe '#image?' do
      it 'returns true for an image file' do
        allow(custom_class).to receive(:filename).and_return('dk.png')

        expect(custom_class).to be_image
      end

      it 'returns false if file has a dangerous image extension' do
        allow(custom_class).to receive(:filename).and_return('unsanitized.svg')

        expect(custom_class).to be_dangerous_image
        expect(custom_class).not_to be_image
      end

      it 'returns false for a video file' do
        allow(custom_class).to receive(:filename).and_return('video_sample.mp4')

        expect(custom_class).not_to be_image
      end

      it 'returns false for an audio file' do
        allow(custom_class).to receive(:filename).and_return('audio_sample.wav')

        expect(custom_class).not_to be_image
      end

      it 'returns false if filename is blank' do
        allow(custom_class).to receive(:filename).and_return(nil)

        expect(custom_class).not_to be_image
      end
    end

    describe '#video?' do
      it 'returns true for a video file' do
        allow(custom_class).to receive(:filename).and_return('video_sample.mp4')

        expect(custom_class).to be_video
      end

      it 'returns false for an image file' do
        allow(custom_class).to receive(:filename).and_return('dk.png')

        expect(custom_class).not_to be_video
      end

      it 'returns false for an audio file' do
        allow(custom_class).to receive(:filename).and_return('audio_sample.wav')

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

    describe '#audio?' do
      it 'returns true for an audio file' do
        allow(custom_class).to receive(:filename).and_return('audio_sample.wav')

        expect(custom_class).to be_audio
      end

      it 'returns false for an image file' do
        allow(custom_class).to receive(:filename).and_return('dk.png')

        expect(custom_class).not_to be_audio
      end

      it 'returns false for a video file' do
        allow(custom_class).to receive(:filename).and_return('video_sample.mp4')

        expect(custom_class).not_to be_audio
      end

      it 'returns false if file has a dangerous image extension' do
        allow(custom_class).to receive(:filename).and_return('unsanitized.svg')

        expect(custom_class).to be_dangerous_image
        expect(custom_class).not_to be_audio
      end

      it 'returns false if filename is blank' do
        allow(custom_class).to receive(:filename).and_return(nil)

        expect(custom_class).not_to be_audio
      end
    end

    describe '#embeddable?' do
      it 'returns true for an image file' do
        allow(custom_class).to receive(:filename).and_return('dk.png')

        expect(custom_class).to be_embeddable
      end

      it 'returns true for a video file' do
        allow(custom_class).to receive(:filename).and_return('video_sample.mp4')

        expect(custom_class).to be_embeddable
      end

      it 'returns true for an audio file' do
        allow(custom_class).to receive(:filename).and_return('audio_sample.wav')

        expect(custom_class).to be_embeddable
      end

      it 'returns false if not an embeddable file' do
        allow(custom_class).to receive(:filename).and_return('doc_sample.txt')

        expect(custom_class).not_to be_embeddable
      end

      it 'returns false if filename has a dangerous image extension' do
        allow(custom_class).to receive(:filename).and_return('unsanitized.svg')

        expect(custom_class).to be_dangerous_image
        expect(custom_class).not_to be_embeddable
      end

      it 'returns false if filename is blank' do
        allow(custom_class).to receive(:filename).and_return(nil)

        expect(custom_class).not_to be_embeddable
      end
    end

    describe '#dangerous_image?' do
      it 'returns true if file has a dangerous image extension' do
        allow(custom_class).to receive(:filename).and_return('unsanitized.svg')

        expect(custom_class).to be_dangerous_image
      end

      it 'returns false for an image file' do
        allow(custom_class).to receive(:filename).and_return('dk.png')

        expect(custom_class).not_to be_dangerous_image
      end

      it 'returns false for a video file' do
        allow(custom_class).to receive(:filename).and_return('video_sample.mp4')

        expect(custom_class).not_to be_dangerous_image
      end

      it 'returns false for an audio file' do
        allow(custom_class).to receive(:filename).and_return('audio_sample.wav')

        expect(custom_class).not_to be_dangerous_image
      end

      it 'returns false if filename is blank' do
        allow(custom_class).to receive(:filename).and_return(nil)

        expect(custom_class).not_to be_dangerous_image
      end
    end

    describe '#dangerous_video?' do
      it 'returns false for a safe video file' do
        allow(custom_class).to receive(:filename).and_return('video_sample.mp4')

        expect(custom_class).not_to be_dangerous_video
      end

      it 'returns false for an image file' do
        allow(custom_class).to receive(:filename).and_return('dk.png')

        expect(custom_class).not_to be_dangerous_video
      end

      it 'returns false for an audio file' do
        allow(custom_class).to receive(:filename).and_return('audio_sample.wav')

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

    describe '#dangerous_audio?' do
      it 'returns false for a safe audio file' do
        allow(custom_class).to receive(:filename).and_return('audio_sample.wav')

        expect(custom_class).not_to be_dangerous_audio
      end

      it 'returns false for an image file' do
        allow(custom_class).to receive(:filename).and_return('dk.png')

        expect(custom_class).not_to be_dangerous_audio
      end

      it 'returns false for a video file' do
        allow(custom_class).to receive(:filename).and_return('video_sample.mp4')

        expect(custom_class).not_to be_dangerous_audio
      end

      it 'returns false if file has a dangerous image extension' do
        allow(custom_class).to receive(:filename).and_return('unsanitized.svg')

        expect(custom_class).not_to be_dangerous_audio
      end

      it 'returns false if filename is blank' do
        allow(custom_class).to receive(:filename).and_return(nil)

        expect(custom_class).not_to be_dangerous_audio
      end
    end

    describe '#dangerous_embeddable?' do
      it 'returns true if file has a dangerous image extension' do
        allow(custom_class).to receive(:filename).and_return('unsanitized.svg')

        expect(custom_class).to be_dangerous_embeddable
      end

      it 'returns false for an image file' do
        allow(custom_class).to receive(:filename).and_return('dk.png')

        expect(custom_class).not_to be_dangerous_embeddable
      end

      it 'returns false for a video file' do
        allow(custom_class).to receive(:filename).and_return('video_sample.mp4')

        expect(custom_class).not_to be_dangerous_embeddable
      end

      it 'returns false for an audio file' do
        allow(custom_class).to receive(:filename).and_return('audio_sample.wav')

        expect(custom_class).not_to be_dangerous_embeddable
      end

      it 'returns false for a non-embeddable file' do
        allow(custom_class).to receive(:filename).and_return('doc_sample.txt')

        expect(custom_class).not_to be_dangerous_embeddable
      end

      it 'returns false if filename is blank' do
        allow(custom_class).to receive(:filename).and_return(nil)

        expect(custom_class).not_to be_dangerous_embeddable
      end
    end
  end
end
