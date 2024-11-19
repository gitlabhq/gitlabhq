# frozen_string_literal: true

require 'spec_helper'
require 'carrierwave/storage/fog'

RSpec.describe GitlabUploader, feature_category: :shared do
  let(:uploader_class) { Class.new(described_class) }

  subject(:uploader) { uploader_class.new(double) }

  describe '#file_storage?' do
    context 'when file storage is used' do
      before do
        uploader_class.storage(:file)
      end

      it { is_expected.to be_file_storage }
    end

    context 'when is remote storage' do
      before do
        uploader_class.storage(:fog)
      end

      it { is_expected.not_to be_file_storage }
    end
  end

  describe '#file_cache_storage?' do
    context 'when file storage is used' do
      before do
        expect(uploader_class).to receive(:cache_storage) { CarrierWave::Storage::File }
      end

      it { is_expected.to be_file_cache_storage }
    end

    context 'when is remote storage' do
      before do
        expect(uploader_class).to receive(:cache_storage) { CarrierWave::Storage::Fog }
      end

      it { is_expected.not_to be_file_cache_storage }
    end
  end

  describe '#move_to_cache' do
    it 'is true' do
      expect(subject.move_to_cache).to eq(true)
    end
  end

  describe '#move_to_store' do
    it 'is true' do
      expect(subject.move_to_store).to eq(true)
    end
  end

  describe '#empty_size?' do
    it 'is true' do
      expect(subject.empty_size?).to eq(true)
    end
  end

  describe '#cache!' do
    it 'moves the file from the working directory to the cache directory' do
      # One to get the work dir, the other to remove it
      expect(subject).to receive(:workfile_path).twice.and_call_original
      # Test https://github.com/carrierwavesubject/carrierwave/blob/v1.0.0/lib/carrierwave/sanitized_file.rb#L200
      expect(FileUtils).to receive(:mv).with(anything, /^#{subject.work_dir}/).and_call_original
      expect(FileUtils).to receive(:mv).with(/^#{subject.work_dir}/, /#{subject.cache_dir}/).and_call_original

      fixture = File.join('spec', 'fixtures', 'rails_sample.jpg')
      subject.cache!(fixture_file_upload(fixture))

      expect(subject.file.path).to match(/#{subject.cache_dir}/)
    end
  end

  describe '#replace_file_without_saving!' do
    it 'allows file to be replaced without triggering any callbacks' do
      new_file = CarrierWave::SanitizedFile.new(Tempfile.new)

      expect(subject).not_to receive(:with_callbacks)

      subject.replace_file_without_saving!(new_file)
    end
  end

  describe '#open' do
    context 'when trace is stored in File storage' do
      context 'when file exists' do
        let(:file) do
          fixture_file_upload('spec/fixtures/trace/sample_trace', 'text/plain')
        end

        before do
          subject.store!(file)
        end

        it 'returns io stream' do
          expect(subject.open).to be_a(IO)
        end

        it 'when passing block it yields' do
          expect { |b| subject.open(&b) }.to yield_control
        end
      end

      context 'when file does not exist' do
        it 'returns nil' do
          expect(subject.open).to be_nil
        end

        it 'when passing block it does not yield' do
          expect { |b| subject.open(&b) }.not_to yield_control
        end
      end
    end

    context 'when trace is stored in Object storage' do
      before do
        allow(subject).to receive(:file_storage?) { false }
      end

      context 'when file exists' do
        before do
          allow(subject).to receive(:url) { 'http://object_storage.com/trace' }
        end

        it 'returns http io stream' do
          expect(subject.open).to be_a(Gitlab::HttpIO)
        end

        it 'when passing block it yields' do
          expect { |b| subject.open(&b) }.to yield_control.once
        end
      end

      context 'when file does not exist' do
        it 'returns nil' do
          expect(subject.open).to be_nil
        end

        it 'when passing block it does not yield' do
          expect { |b| subject.open(&b) }.not_to yield_control
        end
      end
    end

    describe '#url_or_file_path' do
      let(:options) { { expire_at: 1.day.from_now } }

      it 'returns url when in remote storage' do
        expect(subject).to receive(:file_storage?).and_return(false)
        expect(subject).to receive(:url).with(options).and_return("http://example.com")

        expect(subject.url_or_file_path(options)).to eq("http://example.com")
      end

      it 'returns url when in remote storage' do
        expect(subject).to receive(:file_storage?).and_return(true)
        expect(subject).to receive(:path).and_return("/tmp/file")

        expect(subject.url_or_file_path(options)).to eq("file:///tmp/file")
      end
    end
  end

  describe '#multi_read' do
    let(:file) { fixture_file_upload('spec/fixtures/trace/sample_trace', 'text/plain') }
    let(:byte_offsets) { [[4, 10], [17, 29]] }

    subject { uploader.multi_read(byte_offsets) }

    before do
      uploader.store!(file)
    end

    it { is_expected.to eq(%w[Running gitlab-runner]) }
  end

  describe '#check_remote_file_existence_on_upload?' do
    subject { uploader.check_remote_file_existence_on_upload? }

    it { is_expected.to be(true) }
  end

  describe '#sync_model_object_store?' do
    subject { uploader.sync_model_object_store? }

    it { is_expected.to be(false) }
  end

  describe '.version' do
    subject { uploader_class.version }

    it { expect { subject }.to raise_error(RuntimeError, /not supported/) }
  end

  describe '.storage_location' do
    it 'sets the identifier for the storage location options' do
      uploader_class.storage_location(:artifacts)

      expect(uploader_class.options).to eq(Gitlab.config.artifacts)
    end

    context 'when given identifier is not known' do
      it 'raises an error' do
        expect { uploader_class.storage_location(:foo) }
          .to raise_error(KeyError)
      end
    end
  end
end
