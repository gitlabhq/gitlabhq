require 'spec_helper'
require Rails.root.join("db", "post_migrate", "20170717111152_cleanup_move_system_upload_folder_symlink.rb")

describe CleanupMoveSystemUploadFolderSymlink do
  let(:migration) { described_class.new }
  let(:test_base) { File.join(Rails.root, 'tmp', 'tests', 'move-system-upload-folder') }
  let(:test_folder) { File.join(test_base, '-', 'system') }

  before do
    allow(migration).to receive(:base_directory).and_return(test_base)
    FileUtils.rm_rf(test_base)
    FileUtils.mkdir_p(test_folder)
    allow(migration).to receive(:say)
  end

  describe '#up' do
    before do
      FileUtils.ln_s(test_folder, File.join(test_base, 'system'))
    end

    it 'removes the symlink' do
      migration.up

      expect(File.exist?(File.join(test_base, 'system'))).to be_falsey
    end
  end

  describe '#down' do
    it 'creates the symlink' do
      migration.down

      expect(File.symlink?(File.join(test_base, 'system'))).to be_truthy
    end
  end
end
