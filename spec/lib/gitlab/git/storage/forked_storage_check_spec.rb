require 'spec_helper'

describe Gitlab::Git::Storage::ForkedStorageCheck, broken_storage: true, skip_database_cleaner: true do
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
      # We're forking a process here that takes too long
      # It will be killed it's parent process will be killed by it's parent
      # and waited for inside `Gitlab::Git::Storage::ForkedStorageCheck.timeout_check`
      allow(described_class).to receive(:check_filesystem_in_process) do
        Process.spawn("sleep 10")
      end
      result = true

      runtime = Benchmark.realtime do
        result = described_class.storage_available?(existing_path, 0.5)
      end

      expect(result).to be_falsey
      expect(runtime).to be < 1.0
    end

    it 'will try the specified amount of times before failing'  do
      allow(described_class).to receive(:check_filesystem_in_process) do
        Process.spawn("sleep 10")
      end

      expect(Process).to receive(:spawn).with('sleep 10').twice
                           .and_call_original

      runtime = Benchmark.realtime do
        described_class.storage_available?(existing_path, 0.5, 2)
      end

      expect(runtime).to be < 1.0
    end

    describe 'when using paths with spaces' do
      let(:test_dir) { Rails.root.join('tmp', 'tests', 'storage_check') }
      let(:path_with_spaces) { File.join(test_dir, 'path with spaces') }

      around do |example|
        FileUtils.mkdir_p(path_with_spaces)
        example.run
        FileUtils.rm_r(test_dir)
      end

      it 'works for paths with spaces' do
        expect(described_class.storage_available?(path_with_spaces)).to be_truthy
      end

      it 'works for a realpath with spaces' do
        symlink_location = File.join(test_dir, 'a symlink')
        FileUtils.ln_s(path_with_spaces, symlink_location)

        expect(described_class.storage_available?(symlink_location)).to be_truthy
      end
    end
  end
end
