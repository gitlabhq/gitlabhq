require 'rails_helper'

describe Upload do
  describe 'assocations' do
    it { is_expected.to belong_to(:model) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:size) }
    it { is_expected.to validate_presence_of(:path) }
    it { is_expected.to validate_presence_of(:model) }
    it { is_expected.to validate_presence_of(:uploader) }
  end

  describe 'callbacks' do
    context 'for a file above the checksum threshold' do
      it 'schedules checksum calculation' do
        stub_const('UploadChecksumWorker', spy)

        upload = described_class.create(
          path: __FILE__,
          size: described_class::CHECKSUM_THRESHOLD + 1.kilobyte,
          model: build_stubbed(:user),
          uploader: double('ExampleUploader')
        )

        expect(UploadChecksumWorker)
          .to have_received(:perform_async).with(upload.id)
      end
    end

    context 'for a file at or below the checksum threshold' do
      it 'calculates checksum immediately before save' do
        upload = described_class.new(
          path: __FILE__,
          size: described_class::CHECKSUM_THRESHOLD,
          model: build_stubbed(:user),
          uploader: double('ExampleUploader')
        )

        expect { upload.save }
          .to change { upload.checksum }.from(nil)
          .to(a_string_matching(/\A\h{64}\z/))
      end
    end

    describe 'after_destroy' do
      context 'uploader is FileUploader-based' do
        subject { create(:upload, :issuable_upload) }

        it 'calls delete_file!' do
          is_expected.to receive(:delete_file!)

          subject.destroy
        end
      end
    end
  end

  describe '#absolute_path' do
    it 'returns the path directly when already absolute' do
      path = '/path/to/namespace/project/secret/file.jpg'
      upload = described_class.new(path: path)

      expect(upload).not_to receive(:uploader_class)

      expect(upload.absolute_path).to eq path
    end

    it "delegates to the uploader's absolute_path method" do
      uploader = spy('FakeUploader')
      upload = described_class.new(path: 'secret/file.jpg')
      expect(upload).to receive(:uploader_class).and_return(uploader)

      upload.absolute_path

      expect(uploader).to have_received(:absolute_path).with(upload)
    end
  end

  describe '#calculate_checksum!' do
    let(:upload) do
      described_class.new(path: __FILE__,
                          size: described_class::CHECKSUM_THRESHOLD - 1.megabyte)
    end

    it 'sets `checksum` to SHA256 sum of the file' do
      expected = Digest::SHA256.file(__FILE__).hexdigest

      expect { upload.calculate_checksum! }
        .to change { upload.checksum }.from(nil).to(expected)
    end

    it 'sets `checksum` to nil for a non-existant file' do
      expect(upload).to receive(:exist?).and_return(false)

      checksum = Digest::SHA256.file(__FILE__).hexdigest
      upload.checksum = checksum

      expect { upload.calculate_checksum! }
        .to change { upload.checksum }.from(checksum).to(nil)
    end
  end

  describe '#exist?' do
    it 'returns true when the file exists' do
      upload = described_class.new(path: __FILE__)

      expect(upload).to exist
    end

    context 'when the file does not exist' do
      it 'returns false' do
        upload = described_class.new(path: "#{__FILE__}-nope")

        expect(upload).not_to exist
      end

      context 'when the record is persisted' do
        it 'sends a message to Sentry' do
          upload = create(:upload, :issuable_upload)

          expect(Gitlab::Sentry).to receive(:enabled?).and_return(true)
          expect(Raven).to receive(:capture_message).with("Upload file does not exist", extra: upload.attributes)

          upload.exist?
        end

        it 'increments a metric counter to signal a problem' do
          upload = create(:upload, :issuable_upload)

          counter = double(:counter)
          expect(counter).to receive(:increment)
          expect(Gitlab::Metrics).to receive(:counter).with(:upload_file_does_not_exist_total, 'The number of times an upload record could not find its file').and_return(counter)

          upload.exist?
        end
      end

      context 'when the record is not persisted' do
        it 'does not send a message to Sentry' do
          upload = described_class.new(path: "#{__FILE__}-nope")

          expect(Raven).not_to receive(:capture_message)

          upload.exist?
        end

        it 'does not increment a metric counter' do
          upload = described_class.new(path: "#{__FILE__}-nope")

          expect(Gitlab::Metrics).not_to receive(:counter)

          upload.exist?
        end
      end
    end
  end

  describe "#uploader_context" do
    subject { create(:upload, :issuable_upload, secret: 'secret', filename: 'file.txt') }

    it { expect(subject.uploader_context).to match(a_hash_including(secret: 'secret', identifier: 'file.txt')) }
  end
end
