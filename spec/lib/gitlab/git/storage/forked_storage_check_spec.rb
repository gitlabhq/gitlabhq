require 'spec_helper'

describe Gitlab::Git::Storage::ForkedStorageCheck, skip_database_cleaner: true do
  let(:existing_path) do
    existing_path = TestEnv.repos_path
    FileUtils.mkdir_p(existing_path)
    existing_path
  end

  describe '.storage_accessible?' do
    it 'detects when a storage is not available' do
      expect(described_class.storage_available?('/non/existant/path')).to be_falsey
    end

    it 'detects when a storage is available' do
      expect(described_class.storage_available?(existing_path)).to be_truthy
    end

    it 'returns false when the check takes to long' do
      allow(described_class).to receive(:check_filesystem_in_fork) do
        fork { sleep 10 }
      end

      expect(described_class.storage_available?(existing_path, 0.5)).to be_falsey
    end
  end
end
