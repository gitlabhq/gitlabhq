require 'rails_helper'
require 'carrierwave/storage/fog'

describe GitlabUploader do
  let(:uploader_class) { Class.new(described_class) }

  subject { uploader_class.new }

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
end
