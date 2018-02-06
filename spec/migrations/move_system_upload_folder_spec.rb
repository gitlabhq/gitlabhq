require 'spec_helper'
require Rails.root.join("db", "migrate", "20170717074009_move_system_upload_folder.rb")

describe MoveSystemUploadFolder do
  let(:migration) { described_class.new }
  let(:test_base) { File.join(Rails.root, 'tmp', 'tests', 'move-system-upload-folder') }

  before do
    allow(migration).to receive(:base_directory).and_return(test_base)
    FileUtils.rm_rf(test_base)
    FileUtils.mkdir_p(test_base)
    allow(migration).to receive(:say)
  end

  describe '#up' do
    let(:test_folder) { File.join(test_base, 'system') }
    let(:test_file) { File.join(test_folder, 'file') }

    before do
      FileUtils.mkdir_p(test_folder)
      FileUtils.touch(test_file)
    end

    it 'moves the related folder' do
      migration.up

      expect(File.exist?(File.join(test_base, '-', 'system', 'file'))).to be_truthy
    end

    it 'creates a symlink linking making the new folder available on the old path' do
      migration.up

      expect(File.symlink?(File.join(test_base, 'system'))).to be_truthy
      expect(File.exist?(File.join(test_base, 'system', 'file'))).to be_truthy
    end

    it 'does not move if the target directory already exists' do
      FileUtils.mkdir_p(File.join(test_base, '-', 'system'))

      expect(FileUtils).not_to receive(:mv)
      expect(migration).to receive(:say).with(/already exists. No need to redo the move/)

      migration.up
    end
  end

  describe '#down' do
    let(:test_folder) { File.join(test_base, '-', 'system') }
    let(:test_file) { File.join(test_folder, 'file') }

    before do
      FileUtils.mkdir_p(test_folder)
      FileUtils.touch(test_file)
    end

    it 'moves the system folder back to the old location' do
      migration.down

      expect(File.exist?(File.join(test_base, 'system', 'file'))).to be_truthy
    end

    it 'removes the symlink if it existed' do
      FileUtils.ln_s(test_folder, File.join(test_base, 'system'))

      migration.down

      expect(File.directory?(File.join(test_base, 'system'))).to be_truthy
      expect(File.symlink?(File.join(test_base, 'system'))).to be_falsey
    end

    it 'does not move if the old directory already exists' do
      FileUtils.mkdir_p(File.join(test_base, 'system'))

      expect(FileUtils).not_to receive(:mv)
      expect(migration).to receive(:say).with(/already exists and is not a symlink, no need to revert/)

      migration.down
    end
  end
end
