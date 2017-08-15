require "spec_helper"
require Rails.root.join("db", "migrate", "20170316163845_move_uploads_to_system_dir.rb")

describe MoveUploadsToSystemDir do
  let(:migration) { described_class.new }
  let(:test_dir) { File.join(Rails.root, "tmp", "move_uploads_test") }
  let(:uploads_dir) { File.join(test_dir, "public", "uploads") }
  let(:new_uploads_dir) { File.join(uploads_dir, "-", "system") }

  before do
    FileUtils.remove_dir(test_dir) if File.directory?(test_dir)
    FileUtils.mkdir_p(uploads_dir)
    allow(migration).to receive(:base_directory).and_return(test_dir)
    allow(migration).to receive(:say)
  end

  describe "#up" do
    before do
      FileUtils.mkdir_p(File.join(uploads_dir, 'user'))
      FileUtils.touch(File.join(uploads_dir, 'user', 'dummy.file'))
    end

    it 'moves the directory to the new path' do
      expected_path = File.join(new_uploads_dir, 'user', 'dummy.file')

      migration.up

      expect(File.exist?(expected_path)).to be(true)
    end

    it 'creates a symlink in the old location' do
      symlink_path = File.join(uploads_dir, 'user')
      expected_path = File.join(symlink_path, 'dummy.file')

      migration.up

      expect(File.exist?(expected_path)).to be(true)
      expect(File.symlink?(symlink_path)).to be(true)
    end
  end

  describe "#down" do
    before do
      FileUtils.mkdir_p(File.join(new_uploads_dir, 'user'))
      FileUtils.touch(File.join(new_uploads_dir, 'user', 'dummy.file'))
    end

    it 'moves the directory to the old path' do
      expected_path = File.join(uploads_dir, 'user', 'dummy.file')

      migration.down

      expect(File.exist?(expected_path)).to be(true)
    end

    it 'removes the symlink if it existed' do
      FileUtils.ln_s(File.join(new_uploads_dir, 'user'), File.join(uploads_dir, 'user'))

      directory = File.join(uploads_dir, 'user')
      expected_path = File.join(directory, 'dummy.file')

      migration.down

      expect(File.exist?(expected_path)).to be(true)
      expect(File.symlink?(directory)).to be(false)
    end
  end
end
