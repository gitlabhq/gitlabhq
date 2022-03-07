# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::ImportExport::CommandLineUtil do
  include ExportFileHelper

  let(:path) { "#{Dir.tmpdir}/symlink_test" }
  let(:archive) { 'spec/fixtures/symlink_export.tar.gz' }
  let(:shared) { Gitlab::ImportExport::Shared.new(nil) }
  let(:tmpdir) { Dir.mktmpdir }

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
    subject.untar_zxf(archive: archive, dir: path)
  end

  after do
    FileUtils.rm_rf(path)
    FileUtils.remove_entry(tmpdir)
  end

  it 'has the right mask for project.json' do
    expect(file_permissions("#{path}/project.json")).to eq(0755) # originally 777
  end

  it 'has the right mask for uploads' do
    expect(file_permissions("#{path}/uploads")).to eq(0755) # originally 555
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
    before do
      stub_request(:get, 'http://localhost:3000/file')
        .to_return(
          status: 200,
          body: File.open(archive),
          headers: {
            'Content-Type' => 'application/x-tar'
          }
        )
    end

    let(:tempfile) { Tempfile.new('test', path) }

    it 'downloads the file in the given path' do
      subject.download('http://localhost:3000/file', tempfile)

      expect(File.exist?(tempfile)).to eq(true)
      expect(tempfile.size).to eq(File.size(archive))
    end

    it 'limit the size of the downloaded file' do
      subject.download('http://localhost:3000/file', tempfile, size_limit: 1.byte)

      expect(File.exist?(tempfile)).to eq(true)
      expect(tempfile.size).to eq(0)
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
    let(:archive_dir) { Dir.mktmpdir }

    after do
      FileUtils.remove_entry(archive_dir)
    end

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

  describe '#untar_xf' do
    let(:archive_dir) { Dir.mktmpdir }

    after do
      FileUtils.remove_entry(archive_dir)
    end

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
