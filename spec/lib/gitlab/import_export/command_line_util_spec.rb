# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::ImportExport::CommandLineUtil, feature_category: :importers do
  include ExportFileHelper

  let(:shared) { Gitlab::ImportExport::Shared.new(nil) }
  # Separate where files are written during this test by their kind, to avoid them interfering with each other:
  # - `source_dir` Dir to compress files from.
  # - `target_dir` Dir to decompress archived files into.
  # - `archive_dir` Dir to write any archive files to.
  let(:source_dir) { Dir.mktmpdir }
  let(:target_dir) { Dir.mktmpdir }
  let(:archive_dir) { Dir.mktmpdir }

  subject(:mock_class) do
    Class.new do
      include Gitlab::ImportExport::CommandLineUtil

      def initialize
        @shared = Gitlab::ImportExport::Shared.new(nil)
      end

      # Make the included methods public for testing
      public :download_or_copy_upload, :download
    end.new
  end

  before do
    FileUtils.mkdir_p(source_dir)
  end

  after do
    FileUtils.rm_rf(source_dir)
    FileUtils.rm_rf(target_dir)
    FileUtils.rm_rf(archive_dir)
  end

  shared_examples 'deletes symlinks' do |compression, decompression|
    it 'deletes the symlinks', :aggregate_failures do
      Dir.mkdir("#{source_dir}/.git")
      Dir.mkdir("#{source_dir}/folder")
      FileUtils.touch("#{source_dir}/file.txt")
      FileUtils.touch("#{source_dir}/folder/file.txt")
      FileUtils.touch("#{source_dir}/.gitignore")
      FileUtils.touch("#{source_dir}/.git/config")
      File.symlink('file.txt', "#{source_dir}/.symlink")
      File.symlink('file.txt', "#{source_dir}/.git/.symlink")
      File.symlink('file.txt', "#{source_dir}/folder/.symlink")
      archive_file = File.join(archive_dir, 'symlink_archive.tar.gz')
      subject.public_send(compression, archive: archive_file, dir: source_dir)
      subject.public_send(decompression, archive: archive_file, dir: target_dir)

      expect(File).to exist("#{target_dir}/file.txt")
      expect(File).to exist("#{target_dir}/folder/file.txt")
      expect(File).to exist("#{target_dir}/.gitignore")
      expect(File).to exist("#{target_dir}/.git/config")
      expect(File).not_to exist("#{target_dir}/.symlink")
      expect(File).not_to exist("#{target_dir}/.git/.symlink")
      expect(File).not_to exist("#{target_dir}/folder/.symlink")
    end
  end

  shared_examples 'handles shared hard links' do |compression, decompression|
    let(:archive_file) { File.join(archive_dir, 'hard_link_archive.tar.gz') }

    subject(:decompress) { mock_class.public_send(decompression, archive: archive_file, dir: target_dir) }

    before do
      Dir.mkdir("#{source_dir}/dir")
      FileUtils.touch("#{source_dir}/file.txt")
      FileUtils.touch("#{source_dir}/dir/.file.txt")
      FileUtils.link("#{source_dir}/file.txt", "#{source_dir}/.hard_linked_file.txt")

      mock_class.public_send(compression, archive: archive_file, dir: source_dir)
    end

    it 'raises an exception and deletes the extraction dir', :aggregate_failures do
      expect(FileUtils).to receive(:remove_dir).with(target_dir).and_call_original
      expect(Dir).to exist(target_dir)
      expect { decompress }.to raise_error(described_class::HardLinkError)
      expect(Dir).not_to exist(target_dir)
    end
  end

  shared_examples 'deletes pipes' do |compression, decompression|
    it 'deletes the pipes', :aggregate_failures do
      FileUtils.touch("#{source_dir}/file.txt")
      File.mkfifo("#{source_dir}/pipe")

      archive_file = File.join(archive_dir, 'file_with_pipes.tar.gz')
      subject.public_send(compression, archive: archive_file, dir: source_dir)
      subject.public_send(decompression, archive: archive_file, dir: target_dir)

      expect(File).to exist("#{target_dir}/file.txt")
      expect(File).not_to exist("#{target_dir}/pipe")
    end
  end

  describe '#download_or_copy_upload' do
    let(:upload) { instance_double(Upload, local?: local) }
    let(:uploader) { instance_double(ImportExportUploader, path: :path, url: :url, upload: upload) }
    let(:upload_path) { '/some/path' }

    context 'when the upload is local' do
      let(:local) { true }

      it 'copies the file' do
        expect(subject).to receive(:copy_files).with(:path, upload_path)

        subject.download_or_copy_upload(uploader, upload_path)
      end
    end

    context 'when the upload is remote' do
      let(:local) { false }

      it 'downloads the file' do
        expect(subject).to receive(:download).with(:url, upload_path, size_limit: 0)

        subject.download_or_copy_upload(uploader, upload_path)
      end
    end
  end

  describe '#download' do
    let(:content) { File.open('spec/fixtures/rails_sample.tif') }

    context 'a non-localhost uri' do
      before do
        stub_request(:get, url)
          .to_return(
            status: status,
            body: content
          )
      end

      let(:url) { 'https://gitlab.com/file' }

      context 'with ok status code' do
        let(:status) { HTTP::Status::OK }

        it 'gets the contents' do
          Tempfile.create('test') do |file|
            subject.download(url, file.path)
            expect(file.read).to eq(File.open('spec/fixtures/rails_sample.tif').read)
          end
        end

        it 'streams the contents via Gitlab::HTTP' do
          expect(Gitlab::HTTP).to receive(:get).with(url, hash_including(stream_body: true))

          Tempfile.create('test') do |file|
            subject.download(url, file.path)
          end
        end

        it 'does not get the content over the size_limit' do
          Tempfile.create('test') do |file|
            subject.download(url, file.path, size_limit: 300.kilobytes)
            expect(file.read).to eq('')
          end
        end

        it 'gets the content within the size_limit' do
          Tempfile.create('test') do |file|
            subject.download(url, file.path, size_limit: 400.kilobytes)
            expect(file.read).to eq(File.open('spec/fixtures/rails_sample.tif').read)
          end
        end
      end

      %w[MOVED_PERMANENTLY FOUND SEE_OTHER TEMPORARY_REDIRECT].each do |code|
        context "with a redirect status code #{code}" do
          let(:status) { HTTP::Status.const_get(code, false) }

          it 'logs the redirect' do
            expect(::Import::Framework::Logger).to receive(:warn)

            Tempfile.create('test') do |file|
              subject.download(url, file.path)
            end
          end
        end
      end

      %w[ACCEPTED UNAUTHORIZED BAD_REQUEST].each do |code|
        context "with an invalid status code #{code}" do
          let(:status) { HTTP::Status.const_get(code, false) }

          it 'throws an error' do
            Tempfile.create('test') do |file|
              expect { subject.download(url, file.path) }.to raise_error(Gitlab::ImportExport::Error)
            end
          end
        end
      end
    end

    context 'a localhost uri' do
      include StubRequests

      let(:status) { HTTP::Status::OK }
      let(:url) { "#{host}/foo/bar" }
      let(:host) { 'http://localhost:8081' }

      before do
        # Note: the hostname gets changed to an ip address due to dns_rebind_protection
        stub_dns(url, ip_address: '127.0.0.1')
        stub_request(:get, 'http://127.0.0.1:8081/foo/bar')
          .to_return(
            status: status,
            body: content
          )
      end

      it 'throws a blocked url error' do
        Tempfile.create('test') do |file|
          expect { subject.download(url, file.path) }.to raise_error(Gitlab::HTTP::BlockedUrlError)
        end
      end

      context 'for object_storage uri' do
        let(:enabled_object_storage_setting) do
          {
            'enabled' => true,
            'object_store' =>
            {
              'enabled' => true,
              'connection' => {
                'endpoint' => host
              }
            }
          }
        end

        before do
          allow(Settings).to receive(:external_diffs).and_return(enabled_object_storage_setting)
        end

        it 'gets the content' do
          Tempfile.create('test') do |file|
            subject.download(url, file.path)
            expect(file.read).to eq(File.open('spec/fixtures/rails_sample.tif').read)
          end
        end
      end
    end
  end

  describe '#gzip' do
    let(:path) { source_dir }

    it 'compresses specified file' do
      tempfile = Tempfile.new('test', path)
      filename = File.basename(tempfile.path)

      subject.gzip(dir: path, filename: filename)

      expect(File.exist?("#{tempfile.path}.gz")).to eq(true)
    end

    context 'when exception occurs' do
      it 'raises an exception' do
        expect { subject.gzip(dir: path, filename: 'test') }
          .to raise_error(
            Gitlab::ImportExport::Error,
            %r{File compression or decompression failed. Command exited with error code 1: gzip}
          )
      end
    end
  end

  describe '#gunzip' do
    let(:path) { source_dir }

    it 'decompresses specified file' do
      filename = 'labels.ndjson.gz'
      gz_filepath = "spec/fixtures/bulk_imports/gz/#{filename}"
      FileUtils.copy_file(gz_filepath, File.join(path, filename))

      subject.gunzip(dir: path, filename: filename)

      expect(File.exist?(File.join(path, 'labels.ndjson'))).to eq(true)
    end

    context 'when exception occurs' do
      it 'raises an exception' do
        expect { subject.gunzip(dir: path, filename: 'test') }
          .to raise_error(
            Gitlab::ImportExport::Error,
            %r{File compression or decompression failed. Command exited with error code 1: gzip}
          )
      end
    end
  end

  describe '#tar_cf' do
    it 'archives a folder without compression' do
      archive_file = File.join(archive_dir, 'archive.tar')

      result = subject.tar_cf(archive: archive_file, dir: source_dir)

      expect(result).to eq(true)
      expect(File.exist?(archive_file)).to eq(true)
    end

    context 'when something goes wrong' do
      it 'raises an error' do
        expect(Gitlab::Popen).to receive(:popen).and_return(['Error', 1])

        klass = Class.new do
          include Gitlab::ImportExport::CommandLineUtil
        end.new

        expect { klass.tar_cf(archive: 'test', dir: 'test') }.to raise_error(Gitlab::ImportExport::Error, 'Command exited with error code 1: Error')
      end
    end
  end

  describe '#untar_zxf' do
    let(:tar_archive_fixture) { 'spec/fixtures/symlink_export.tar.gz' }

    it_behaves_like 'deletes symlinks', :tar_czf, :untar_zxf
    it_behaves_like 'handles shared hard links', :tar_czf, :untar_zxf
    it_behaves_like 'deletes pipes', :tar_czf, :untar_zxf

    it 'has the right mask for project.json' do
      subject.untar_zxf(archive: tar_archive_fixture, dir: target_dir)

      expect(file_permissions("#{target_dir}/project.json")).to eq(0755) # originally 777
    end

    it 'has the right mask for uploads' do
      subject.untar_zxf(archive: tar_archive_fixture, dir: target_dir)

      expect(file_permissions("#{target_dir}/uploads")).to eq(0755) # originally 555
    end
  end

  describe '#untar_xf' do
    let(:tar_archive_fixture) { 'spec/fixtures/symlink_export.tar.gz' }

    it_behaves_like 'deletes symlinks', :tar_cf, :untar_xf
    it_behaves_like 'handles shared hard links', :tar_cf, :untar_xf
    it_behaves_like 'deletes pipes', :tar_czf, :untar_zxf

    it 'extracts archive without decompression' do
      filename = 'archive.tar.gz'
      archive_file = File.join(archive_dir, 'archive.tar')

      FileUtils.copy_file(tar_archive_fixture, File.join(archive_dir, filename))
      subject.gunzip(dir: archive_dir, filename: filename)

      result = subject.untar_xf(archive: archive_file, dir: archive_dir)

      expect(result).to eq(true)
      expect(File.exist?(archive_file)).to eq(true)
      expect(File.exist?(File.join(archive_dir, 'project.json'))).to eq(true)
      expect(Dir.exist?(File.join(archive_dir, 'uploads'))).to eq(true)
    end

    context 'when something goes wrong' do
      before do
        expect(Gitlab::Popen).to receive(:popen).and_return(['Error', 1])
      end

      it 'raises an error' do
        klass = Class.new do
          include Gitlab::ImportExport::CommandLineUtil
        end.new

        expect { klass.untar_xf(archive: 'test', dir: 'test') }.to raise_error(Gitlab::ImportExport::Error, 'Command exited with error code 1: Error')
      end

      it 'returns false and includes error status' do
        klass = Class.new do
          include Gitlab::ImportExport::CommandLineUtil

          attr_accessor :shared

          def initialize
            @shared = Gitlab::ImportExport::Shared.new(nil)
          end
        end.new

        expect(klass.tar_czf(archive: 'test', dir: 'test')).to eq(false)
        expect(klass.shared.errors).to eq(['Command exited with error code 1: Error'])
      end
    end
  end
end
