# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::ImportExport::FileImporter, feature_category: :importers do
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

  context 'when tmpdir is provided' do
    include AfterNextHelpers

    subject(:perform_import) do
      described_class.import(
        importable: project,
        archive_file: archive_file,
        shared: shared,
        tmpdir: tmpdir,
        user: user
      )
    end

    let(:archive_file) { nil }
    let(:project) { create(:project) }
    let(:user) { project.creator }
    let!(:import_export_upload) { create(:import_export_upload, project: project, user: user) }
    let(:tmpdir) { Dir.mktmpdir }

    shared_examples 'it cleans the target directory' do
      it 'cleans the target directory' do
        # The extraction directory is cleaned twice: once before extraction and
        # again afterwards.
        expect_next(described_class).to receive(:clean_extraction_dir!).at_least(:twice)

        perform_import
      end
    end

    shared_examples 'it does not clean the target directory' do
      it 'does not clean the directory' do
        expect_next(described_class).not_to receive(:clean_extraction_dir!)

        perform_import
      end
    end

    context 'when the tmpdir is outside of the system tmp folder' do
      let(:tmpdir) { '/etc' }

      it 'records an error and skips the import' do
        perform_import

        expect(shared.errors).to include('path [FILTERED] is not allowed')
      end

      it_behaves_like 'it does not clean the target directory'
    end

    context 'when the tmpdir looks like a path traversal' do
      let(:tmpdir) { "#{Dir.tmpdir}../../../stealin/ur/etc/passwd" }

      it 'records an error and skips the import' do
        perform_import

        expect(shared.errors).to include('Invalid path')
      end

      it_behaves_like 'it does not clean the target directory'
    end

    context 'and the archive file is not provided' do
      it 'copies the archive to the provided temp dir' do
        expected_destination_regex = %r{\A#{tmpdir}/[\w\-]+_export\.tar\.gz\z}

        expect_next(described_class)
          .to receive(:download_or_copy_upload)
          .with(
            an_instance_of(ImportExportUploader),
            a_string_matching(expected_destination_regex),
            kind_of(Hash)
          )

        perform_import
      end

      it_behaves_like 'it cleans the target directory'
    end

    context 'and the archive is provided' do
      let(:archive_file) { File.join(Dir.tmpdir, 'file_importer_spec.gz') }

      before do
        Zlib::GzipWriter.open(archive_file) do |gz|
          gz.write('fake tarball contents')
        end
      end

      it 'extracts the archive to the provided tmp dir' do
        expect_next_instance_of(described_class) do |instance|
          expect(instance).to receive(:untar_zxf).with(
            archive: archive_file,
            dir: tmpdir
          )
        end

        perform_import
      end

      it_behaves_like 'it cleans the target directory'
    end
  end

  context 'as normal run' do
    let(:project) { build(:project) }

    before do
      described_class.import(importable: project, archive_file: '', shared: shared, user: project.creator)
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
      expect(file_permissions(valid_file)).not_to eq(0o0000)
    end

    it 'creates the file in the right subfolder' do
      expect(shared.export_path).to include('test/abcd')
    end

    context 'when the import file is not remote' do
      include AfterNextHelpers

      it 'downloads the file from a remote object storage' do
        project = create(:project)
        create(:import_export_upload, project: project, user: project.creator)

        expect_next(described_class)
          .to receive(:download_or_copy_upload)
          .with(
            anything,
            kind_of(String),
            size_limit: Gitlab::CurrentSettings.current_application_settings.max_import_remote_file_size.megabytes
          )

        described_class.import(importable: project, archive_file: nil, shared: shared, user: project.creator)
      end
    end

    context 'when the import file is remote' do
      include AfterNextHelpers

      it 'downloads the file from a remote object storage' do
        file_url = 'https://remote.url/file'
        project = create(:project)
        create(:import_export_upload, remote_import_url: file_url, project: project,
          user: project.creator)

        expect_next(described_class)
          .to receive(:download)
          .with(
            file_url,
            kind_of(String),
            size_limit: Gitlab::CurrentSettings.current_application_settings.max_import_remote_file_size.megabytes
          )

        described_class.import(importable: project, archive_file: nil, shared: shared, user: project.creator)
      end
    end
  end

  context 'when an error occurs' do
    let(:project) { build(:project) }

    subject(:import) do
      described_class.import(importable: project, archive_file: '', shared: shared, user: project.creator)
    end

    before do
      allow_next_instance_of(described_class) do |instance|
        allow(instance).to receive(:wait_for_archived_file).and_raise(StandardError, 'foo')
      end
    end

    it 'removes symlinks in root folder' do
      import

      expect(File.exist?(symlink_file)).to be false
    end

    it 'removes hidden symlinks in root folder' do
      import

      expect(File.exist?(hidden_symlink_file)).to be false
    end

    it 'removes symlinks in subfolders' do
      import

      expect(File.exist?(subfolder_symlink_file)).to be false
    end

    it 'does not remove a valid file' do
      import

      expect(File.exist?(valid_file)).to be true
    end

    it 'returns false and sets an error on shared' do
      result = import

      expect(result).to eq(false)
      expect(shared.errors.join).to eq('foo')
    end

    context 'when files in the archive share hard links' do
      let(:hard_link_file) { "#{shared.export_path}/hard_link_file.txt" }

      before do
        FileUtils.link(valid_file, hard_link_file)
      end

      it 'returns false and sets an error on shared' do
        result = import

        expect(result).to eq(false)
        expect(shared.errors.join).to eq('File shares hard link')
      end

      it 'removes all files in export path' do
        expect(Dir).to exist(shared.export_path)
        expect(File).to exist(symlink_file)
        expect(File).to exist(hard_link_file)
        expect(File).to exist(valid_file)

        import

        expect(File).not_to exist(symlink_file)
        expect(File).not_to exist(hard_link_file)
        expect(File).not_to exist(valid_file)
        expect(Dir).not_to exist(shared.export_path)
      end
    end
  end

  context 'when file exceeds acceptable decompressed size' do
    let(:project) { create(:project) }
    let(:shared) { Gitlab::ImportExport::Shared.new(project) }
    let(:filepath) { File.join(Dir.tmpdir, 'file_importer_spec.gz') }

    subject(:file_importer) do
      described_class.new(importable: project, archive_file: filepath, shared: shared, user: project.creator)
    end

    before do
      Zlib::GzipWriter.open(filepath) do |gz|
        gz.write('Hello World!')
      end
      stub_application_setting(max_decompressed_archive_size: 0.000001)
    end

    it 'returns false and sets an error on shared' do
      result = file_importer.import

      expect(result).to eq(false)
      expect(shared.errors.join).to eq('Decompressed archive size validation failed.')
    end
  end

  def setup_files
    FileUtils.rm_rf(shared.export_path)
    FileUtils.mkdir_p("#{shared.export_path}/subfolder/")
    FileUtils.touch(valid_file)
    FileUtils.ln_s(valid_file, symlink_file)
    FileUtils.ln_s(valid_file, subfolder_symlink_file)
    FileUtils.ln_s(valid_file, hidden_symlink_file)
    FileUtils.ln_s(valid_file, evil_symlink_file)
    FileUtils.ln_s(valid_file, custom_mode_symlink_file)
    FileUtils.chmod_R(0o0000, custom_mode_symlink_file)
  end
end
