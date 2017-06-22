require 'spec_helper'

describe LfsObjectUploader do
  let(:lfs_object) { create(:lfs_object, :with_file) }
  let(:uploader) { described_class.new(lfs_object) }
  let(:path) { Gitlab.config.lfs.storage_path }

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

  describe '#store_dir' do
    subject { uploader.store_dir }

    it { is_expected.to start_with(path) }
    it { is_expected.to end_with("#{lfs_object.oid[0, 2]}/#{lfs_object.oid[2, 2]}") }
  end

  describe '#cache_dir' do
    subject { uploader.cache_dir }

    it { is_expected.to start_with(path) }
    it { is_expected.to end_with('/tmp/cache') }
  end

  describe '#work_dir' do
    subject { uploader.work_dir }

    it { is_expected.to start_with(path) }
    it { is_expected.to end_with('/tmp/work') }
  end
end
