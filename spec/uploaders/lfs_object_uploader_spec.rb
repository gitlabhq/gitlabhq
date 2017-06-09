require 'spec_helper'

describe LfsObjectUploader do
  let(:uploader) { described_class.new(build_stubbed(:empty_project)) }

  describe '#cache!' do
    it 'caches the file in the cache directory' do
      # One to get the work dir, the other to remove it
      expect(uploader).to receive(:workfile_path).exactly(2).times.and_call_original
      expect(FileUtils).to receive(:mv).with(anything, /^#{uploader.work_dir}/).and_call_original
      expect(FileUtils).to receive(:mv).with(/^#{uploader.work_dir}/, /^#{uploader.cache_dir}/).and_call_original

      fixture = Rails.root.join('spec', 'fixtures', 'rails_sample.jpg')
      uploader.cache!(fixture_file_upload(fixture))

      expect(uploader.file.path).to start_with(uploader.cache_dir)
    end
  end

  describe '#move_to_cache' do
    it 'is true' do
      expect(uploader.move_to_cache).to eq(true)
    end
  end

  describe '#move_to_store' do
    it 'is true' do
      expect(uploader.move_to_store).to eq(true)
    end
  end
end
