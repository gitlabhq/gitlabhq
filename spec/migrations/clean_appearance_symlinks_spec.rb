require 'spec_helper'
require Rails.root.join('db', 'post_migrate', '20170613111224_clean_appearance_symlinks.rb')

describe CleanAppearanceSymlinks do
  let(:migration) { described_class.new }
  let(:test_dir) { File.join(Rails.root, "tmp", "tests", "clean_appearance_test") }
  let(:uploads_dir) { File.join(test_dir, "public", "uploads") }
  let(:new_uploads_dir) { File.join(uploads_dir, "system") }
  let(:original_path) { File.join(new_uploads_dir, 'appearance') }
  let(:symlink_path) { File.join(uploads_dir, 'appearance') }

  before do
    FileUtils.remove_dir(test_dir) if File.directory?(test_dir)
    FileUtils.mkdir_p(uploads_dir)
    allow(migration).to receive(:base_directory).and_return(test_dir)
    allow(migration).to receive(:say)
  end

  describe "#up" do
    before do
      FileUtils.mkdir_p(original_path)
      FileUtils.ln_s(original_path, symlink_path)
    end

    it 'removes the symlink' do
      migration.up

      expect(File.symlink?(symlink_path)).to be(false)
    end
  end

  describe '#down' do
    before do
      FileUtils.mkdir_p(File.join(original_path))
      FileUtils.touch(File.join(original_path, 'dummy.file'))
    end

    it 'creates a symlink' do
      expected_path = File.join(symlink_path, "dummy.file")
      migration.down

      expect(File.exist?(expected_path)).to be(true)
      expect(File.symlink?(symlink_path)).to be(true)
    end
  end
end
