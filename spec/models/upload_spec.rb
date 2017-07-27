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
  end

  describe '.remove_path' do
    it 'removes all records at the given path' do
      described_class.create!(
        size: File.size(__FILE__),
        path: __FILE__,
        model: build_stubbed(:user),
        uploader: 'AvatarUploader'
      )

      expect { described_class.remove_path(__FILE__) }
        .to change { described_class.count }.from(1).to(0)
    end
  end

  describe '.record' do
    let(:fake_uploader) do
      double(
        file: double(size: 12_345),
        relative_path: 'foo/bar.jpg',
        model: build_stubbed(:user),
        class: 'AvatarUploader'
      )
    end

    it 'removes existing paths before creation' do
      expect(described_class).to receive(:remove_path)
        .with(fake_uploader.relative_path)

      described_class.record(fake_uploader)
    end

    it 'creates a new record and assigns size, path, model, and uploader' do
      upload = described_class.record(fake_uploader)

      aggregate_failures do
        expect(upload).to be_persisted
        expect(upload.size).to eq fake_uploader.file.size
        expect(upload.path).to eq fake_uploader.relative_path
        expect(upload.model_id).to eq fake_uploader.model.id
        expect(upload.model_type).to eq fake_uploader.model.class.to_s
        expect(upload.uploader).to eq fake_uploader.class
      end
    end
  end

  describe '.hexdigest' do
    it 'calculates the SHA256 sum' do
      expected = Digest::SHA256.file(__FILE__).hexdigest

      expect(described_class.hexdigest(__FILE__)).to eq expected
    end

    it 'returns nil for a non-existant file' do
      expect(described_class.hexdigest("#{__FILE__}-nope")).to be_nil
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

  describe '#calculate_checksum' do
    it 'calculates the SHA256 sum' do
      upload = described_class.new(
        path: __FILE__,
        size: described_class::CHECKSUM_THRESHOLD - 1.megabyte
      )
      expected = Digest::SHA256.file(__FILE__).hexdigest

      expect { upload.calculate_checksum }
        .to change { upload.checksum }.from(nil).to(expected)
    end

    it 'returns nil for a non-existant file' do
      upload = described_class.new(
        path: __FILE__,
        size: described_class::CHECKSUM_THRESHOLD - 1.megabyte
      )

      expect(upload).to receive(:exist?).and_return(false)

      expect(upload.calculate_checksum).to be_nil
    end
  end

  describe '#exist?' do
    it 'returns true when the file exists' do
      upload = described_class.new(path: __FILE__)

      expect(upload).to exist
    end

    it 'returns false when the file does not exist' do
      upload = described_class.new(path: "#{__FILE__}-nope")

      expect(upload).not_to exist
    end
  end
end
