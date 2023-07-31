# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::ImportExport::CommandLineUtil, feature_category: :importers do
  include ExportFileHelper

  let(:path) { "#{Dir.tmpdir}/symlink_test" }
  let(:archive) { 'spec/fixtures/symlink_export.tar.gz' }
  let(:shared) { Gitlab::ImportExport::Shared.new(nil) }
  let(:tmpdir) { Dir.mktmpdir }
  let(:archive_dir) { Dir.mktmpdir }

  subject do
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
    FileUtils.mkdir_p(path)
  end

  after do
    FileUtils.rm_rf(path)
    FileUtils.rm_rf(archive_dir)
    FileUtils.remove_entry(tmpdir)
  end

  shared_examples 'deletes symlinks' do |compression, decompression|
    it 'deletes the symlinks', :aggregate_failures do
      Dir.mkdir("#{tmpdir}/.git")
      Dir.mkdir("#{tmpdir}/folder")
      FileUtils.touch("#{tmpdir}/file.txt")
      FileUtils.touch("#{tmpdir}/folder/file.txt")
      FileUtils.touch("#{tmpdir}/.gitignore")
      FileUtils.touch("#{tmpdir}/.git/config")
      File.symlink('file.txt', "#{tmpdir}/.symlink")
      File.symlink('file.txt', "#{tmpdir}/.git/.symlink")
      File.symlink('file.txt', "#{tmpdir}/folder/.symlink")
      archive = File.join(archive_dir, 'archive')
      subject.public_send(compression, archive: archive, dir: tmpdir)

      subject.public_send(decompression, archive: archive, dir: archive_dir)

      expect(File.exist?("#{archive_dir}/file.txt")).to eq(true)
      expect(File.exist?("#{archive_dir}/folder/file.txt")).to eq(true)
      expect(File.exist?("#{archive_dir}/.gitignore")).to eq(true)
      expect(File.exist?("#{archive_dir}/.git/config")).to eq(true)
      expect(File.exist?("#{archive_dir}/.symlink")).to eq(false)
      expect(File.exist?("#{archive_dir}/.git/.symlink")).to eq(false)
      expect(File.exist?("#{archive_dir}/folder/.symlink")).to eq(false)
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
        expect(subject).to receive(:download).with(:url, upload_path, size_limit: nil)

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
            expect(Gitlab::Import::Logger).to receive(:warn)

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
          expect { subject.download(url, file.path) }.to raise_error((Gitlab::HTTP::BlockedUrlError))
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
    it 'compresses specified file' do
      tempfile = Tempfile.new('test', path)
      filename = File.basename(tempfile.path)

      subject.gzip(dir: path, filename: filename)

      expect(File.exist?("#{tempfile.path}.gz")).to eq(true)
    end

    context 'when exception occurs' do
      it 'raises an exception' do
        expect { subject.gzip(dir: path, filename: 'test') }.to raise_error(Gitlab::ImportExport::Error)
      end
    end
  end

  describe '#gunzip' do
    it 'decompresses specified file' do
      filename = 'labels.ndjson.gz'
      gz_filepath = "spec/fixtures/bulk_imports/gz/#{filename}"
      FileUtils.copy_file(gz_filepath, File.join(tmpdir, filename))

      subject.gunzip(dir: tmpdir, filename: filename)

      expect(File.exist?(File.join(tmpdir, 'labels.ndjson'))).to eq(true)
    end

    context 'when exception occurs' do
      it 'raises an exception' do
        expect { subject.gunzip(dir: path, filename: 'test') }.to raise_error(Gitlab::ImportExport::Error)
      end
    end
  end

  describe '#tar_cf' do
    it 'archives a folder without compression' do
      archive_file = File.join(archive_dir, 'archive.tar')

      result = subject.tar_cf(archive: archive_file, dir: tmpdir)

      expect(result).to eq(true)
      expect(File.exist?(archive_file)).to eq(true)
    end

    context 'when something goes wrong' do
      it 'raises an error' do
        expect(Gitlab::Popen).to receive(:popen).and_return(['Error', 1])

        klass = Class.new do
          include Gitlab::ImportExport::CommandLineUtil
        end.new

        expect { klass.tar_cf(archive: 'test', dir: 'test') }.to raise_error(Gitlab::ImportExport::Error, 'command exited with error code 1: Error')
      end
    end
  end

  describe '#untar_zxf' do
    it_behaves_like 'deletes symlinks', :tar_czf, :untar_zxf

    it 'has the right mask for project.json' do
      subject.untar_zxf(archive: archive, dir: path)

      expect(file_permissions("#{path}/project.json")).to eq(0755) # originally 777
    end

    it 'has the right mask for uploads' do
      subject.untar_zxf(archive: archive, dir: path)

      expect(file_permissions("#{path}/uploads")).to eq(0755) # originally 555
    end
  end

  describe '#untar_xf' do
    it_behaves_like 'deletes symlinks', :tar_cf, :untar_xf

    it 'extracts archive without decompression' do
      filename = 'archive.tar.gz'
      archive_file = File.join(archive_dir, 'archive.tar')

      FileUtils.copy_file(archive, File.join(archive_dir, filename))
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

        expect { klass.untar_xf(archive: 'test', dir: 'test') }.to raise_error(Gitlab::ImportExport::Error, 'command exited with error code 1: Error')
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
        expect(klass.shared.errors).to eq(['command exited with error code 1: Error'])
      end
    end
  end
end
