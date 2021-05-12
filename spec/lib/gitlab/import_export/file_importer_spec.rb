# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::ImportExport::FileImporter do
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

    allow_next_instance_of(Gitlab::ImportExport) do |instance|
      allow(instance).to receive(:storage_path).and_return(storage_path)
    end
    allow_next_instance_of(Gitlab::ImportExport::CommandLineUtil) do |instance|
      allow(instance).to receive(:untar_zxf).and_return(true)
    end
    allow_next_instance_of(Gitlab::ImportExport::Shared) do |instance|
      allow(instance).to receive(:relative_archive_path).and_return('test')
    end
    allow(SecureRandom).to receive(:hex).and_return('abcd')
    setup_files
  end

  after do
    FileUtils.rm_rf(storage_path)
  end

  context 'normal run' do
    before do
      described_class.import(importable: build(:project), archive_file: '', shared: shared)
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

    context 'when the import file is remote' do
      include AfterNextHelpers

      it 'downloads the file from a remote object storage' do
        file_url = 'https://remote.url/file'
        import_export_upload = build(:import_export_upload, remote_import_url: file_url)
        project = build( :project, import_export_upload: import_export_upload)

        expect_next(described_class)
          .to receive(:download)
          .with(file_url, kind_of(String))

        described_class.import(importable: project, archive_file: nil, shared: shared)
      end
    end
  end

  context 'error' do
    before do
      allow_next_instance_of(described_class) do |instance|
        allow(instance).to receive(:wait_for_archived_file).and_raise(StandardError)
      end
      described_class.import(importable: build(:project), archive_file: '', shared: shared)
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

  context 'when file exceeds acceptable decompressed size' do
    let(:project) { create(:project) }
    let(:shared) { Gitlab::ImportExport::Shared.new(project) }
    let(:filepath) { File.join(Dir.tmpdir, 'file_importer_spec.gz') }

    subject { described_class.new(importable: project, archive_file: filepath, shared: shared) }

    before do
      Zlib::GzipWriter.open(filepath) do |gz|
        gz.write('Hello World!')
      end
    end

    context 'when validate_import_decompressed_archive_size feature flag is enabled' do
      before do
        stub_feature_flags(validate_import_decompressed_archive_size: true)

        allow(Gitlab::ImportExport::DecompressedArchiveSizeValidator).to receive(:max_bytes).and_return(1)
      end

      it 'returns false' do
        expect(subject.import).to eq(false)
        expect(shared.errors.join).to eq('Decompressed archive size validation failed.')
      end
    end

    context 'when validate_import_decompressed_archive_size feature flag is disabled' do
      before do
        stub_feature_flags(validate_import_decompressed_archive_size: false)
      end

      it 'skips validation' do
        expect(subject).to receive(:validate_decompressed_archive_size).never

        subject.import
      end
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
