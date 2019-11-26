# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::ImportExport::FileImporter do
  include ExportFileHelper

  let(:shared) { Gitlab::ImportExport::Shared.new(nil) }
  let(:storage_path) { "#{Dir.tmpdir}/file_importer_spec" }
  let(:valid_file) { "#{shared.export_path}/valid.json" }
  let(:symlink_file) { "#{shared.export_path}/invalid.json" }
  let(:hidden_symlink_file) { "#{shared.export_path}/.hidden" }
  let(:subfolder_symlink_file) { "#{shared.export_path}/subfolder/invalid.json" }
  let(:evil_symlink_file) { "#{shared.export_path}/.\nevil" }
  let(:custom_mode_symlink_file) { "#{shared.export_path}/symlink.mode" }

  before do
    stub_const('Gitlab::ImportExport::FileImporter::MAX_RETRIES', 0)
    stub_uploads_object_storage(FileUploader)

    allow_any_instance_of(Gitlab::ImportExport).to receive(:storage_path).and_return(storage_path)
    allow_any_instance_of(Gitlab::ImportExport::CommandLineUtil).to receive(:untar_zxf).and_return(true)
    allow_any_instance_of(Gitlab::ImportExport::Shared).to receive(:relative_archive_path).and_return('test')
    allow(SecureRandom).to receive(:hex).and_return('abcd')
    setup_files
  end

  after do
    FileUtils.rm_rf(storage_path)
  end

  context 'normal run' do
    before do
      described_class.import(project: build(:project), archive_file: '', shared: shared)
    end

    it 'removes symlinks in root folder' do
      expect(File.exist?(symlink_file)).to be false
    end

    it 'removes hidden symlinks in root folder' do
      expect(File.exist?(hidden_symlink_file)).to be false
    end

    it 'removes evil symlinks in root folder' do
      expect(File.exist?(evil_symlink_file)).to be false
    end

    it 'removes symlinks in subfolders' do
      expect(File.exist?(subfolder_symlink_file)).to be false
    end

    it 'removes symlinks without any file permissions' do
      expect(File.exist?(custom_mode_symlink_file)).to be false
    end

    it 'does not remove a valid file' do
      expect(File.exist?(valid_file)).to be true
    end

    it 'does not change a valid file permissions' do
      expect(file_permissions(valid_file)).not_to eq(0000)
    end

    it 'creates the file in the right subfolder' do
      expect(shared.export_path).to include('test/abcd')
    end
  end

  context 'error' do
    before do
      allow_any_instance_of(described_class).to receive(:wait_for_archived_file).and_raise(StandardError)
      described_class.import(project: build(:project), archive_file: '', shared: shared)
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
    FileUtils.ln_s(valid_file, hidden_symlink_file)
    FileUtils.ln_s(valid_file, evil_symlink_file)
    FileUtils.ln_s(valid_file, custom_mode_symlink_file)
    FileUtils.chmod_R(0000, custom_mode_symlink_file)
  end
end
