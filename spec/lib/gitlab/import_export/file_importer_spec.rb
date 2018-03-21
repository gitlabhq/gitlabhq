require 'spec_helper'

describe Gitlab::ImportExport::FileImporter do
  let(:shared) { Gitlab::ImportExport::Shared.new(nil) }
  let(:export_path) { "#{Dir.tmpdir}/file_importer_spec" }
  let(:valid_file) { "#{shared.export_path}/valid.json" }
  let(:symlink_file) { "#{shared.export_path}/invalid.json" }
  let(:hidden_symlink_file) { "#{shared.export_path}/.hidden" }
  let(:subfolder_symlink_file) { "#{shared.export_path}/subfolder/invalid.json" }

  before do
    stub_const('Gitlab::ImportExport::FileImporter::MAX_RETRIES', 0)
    allow_any_instance_of(Gitlab::ImportExport).to receive(:storage_path).and_return(export_path)
    allow_any_instance_of(Gitlab::ImportExport::CommandLineUtil).to receive(:untar_zxf).and_return(true)
    allow_any_instance_of(Gitlab::ImportExport::Shared).to receive(:relative_archive_path).and_return('test')
    allow(SecureRandom).to receive(:hex).and_return('abcd')
    setup_files
  end

  after do
    FileUtils.rm_rf(export_path)
  end

  context 'normal run' do
    before do
      described_class.import(archive_file: '', shared: shared)
    end

    it 'removes symlinks in root folder' do
      expect(File.exist?(symlink_file)).to be false
    end

    it 'removes hidden symlinks in root folder' do
      expect(File.exist?(hidden_symlink_file)).to be false
    end

    it 'removes symlinks in subfolders' do
      expect(File.exist?(subfolder_symlink_file)).to be false
    end

    it 'does not remove a valid file' do
      expect(File.exist?(valid_file)).to be true
    end

    it 'creates the file in the right subfolder' do
      expect(shared.export_path).to include('test/abcd')
    end
  end

  context 'error' do
    before do
      allow_any_instance_of(described_class).to receive(:wait_for_archived_file).and_raise(StandardError)
      described_class.import(archive_file: '', shared: shared)
    end

    it 'removes symlinks in root folder' do
      expect(File.exist?(symlink_file)).to be false
    end

    it 'removes hidden symlinks in root folder' do
      expect(File.exist?(hidden_symlink_file)).to be false
    end

    it 'removes symlinks in subfolders' do
      expect(File.exist?(subfolder_symlink_file)).to be false
    end

    it 'does not remove a valid file' do
      expect(File.exist?(valid_file)).to be true
    end
  end

  def setup_files
    FileUtils.mkdir_p("#{shared.export_path}/subfolder/")
    FileUtils.touch(valid_file)
    FileUtils.ln_s(valid_file, symlink_file)
    FileUtils.ln_s(valid_file, subfolder_symlink_file)
  end
end
