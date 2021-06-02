# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::ImportExport::CommandLineUtil do
  include ExportFileHelper

  let(:path) { "#{Dir.tmpdir}/symlink_test" }
  let(:archive) { 'spec/fixtures/symlink_export.tar.gz' }
  let(:shared) { Gitlab::ImportExport::Shared.new(nil) }

  subject do
    Class.new do
      include Gitlab::ImportExport::CommandLineUtil

      def initialize
        @shared = Gitlab::ImportExport::Shared.new(nil)
      end
    end.new
  end

  before do
    FileUtils.mkdir_p(path)
    subject.untar_zxf(archive: archive, dir: path)
  end

  after do
    FileUtils.rm_rf(path)
  end

  it 'has the right mask for project.json' do
    expect(file_permissions("#{path}/project.json")).to eq(0755) # originally 777
  end

  it 'has the right mask for uploads' do
    expect(file_permissions("#{path}/uploads")).to eq(0755) # originally 555
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
      tmpdir = Dir.mktmpdir
      filename = 'labels.ndjson.gz'
      gz_filepath = "spec/fixtures/bulk_imports/gz/#{filename}"
      FileUtils.copy_file(gz_filepath, File.join(tmpdir, filename))

      subject.gunzip(dir: tmpdir, filename: filename)

      expect(File.exist?(File.join(tmpdir, 'labels.ndjson'))).to eq(true)

      FileUtils.remove_entry(tmpdir)
    end

    context 'when exception occurs' do
      it 'raises an exception' do
        expect { subject.gunzip(dir: path, filename: 'test') }.to raise_error(Gitlab::ImportExport::Error)
      end
    end
  end
end
