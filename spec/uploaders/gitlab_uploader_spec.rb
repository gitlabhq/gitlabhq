require 'rails_helper'
require 'carrierwave/storage/fog'

describe GitlabUploader do
  let(:uploader_class) { Class.new(described_class) }

  subject { uploader_class.new(double) }

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
        uploader_class.cache_storage(:file)
      end

      it { is_expected.to be_file_cache_storage }
    end

    context 'when is remote storage' do
      before do
        uploader_class.cache_storage(:fog)
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

  describe '#cache!' do
    it 'moves the file from the working directory to the cache directory' do
      # One to get the work dir, the other to remove it
      expect(subject).to receive(:workfile_path).exactly(2).times.and_call_original
      # Test https://github.com/carrierwavesubject/carrierwave/blob/v1.0.0/lib/carrierwave/sanitized_file.rb#L200
      expect(FileUtils).to receive(:mv).with(anything, /^#{subject.work_dir}/).and_call_original
      expect(FileUtils).to receive(:mv).with(/^#{subject.work_dir}/, /#{subject.cache_dir}/).and_call_original

      fixture = Rails.root.join('spec', 'fixtures', 'rails_sample.jpg')
      subject.cache!(fixture_file_upload(fixture))

      expect(subject.file.path).to match(/#{subject.cache_dir}/)
    end
  end
end
