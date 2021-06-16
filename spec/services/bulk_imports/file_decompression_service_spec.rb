# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::FileDecompressionService do
  let_it_be(:tmpdir) { Dir.mktmpdir }
  let_it_be(:ndjson_filename) { 'labels.ndjson' }
  let_it_be(:ndjson_filepath) { File.join(tmpdir, ndjson_filename) }
  let_it_be(:gz_filename) { "#{ndjson_filename}.gz" }
  let_it_be(:gz_filepath) { "spec/fixtures/bulk_imports/gz/#{gz_filename}" }

  before do
    FileUtils.copy_file(gz_filepath, File.join(tmpdir, gz_filename))
    FileUtils.remove_entry(ndjson_filepath) if File.exist?(ndjson_filepath)
  end

  after(:all) do
    FileUtils.remove_entry(tmpdir)
  end

  subject { described_class.new(dir: tmpdir, filename: gz_filename) }

  describe '#execute' do
    it 'decompresses specified file' do
      subject.execute

      expect(File.exist?(File.join(tmpdir, ndjson_filename))).to eq(true)
      expect(File.open(ndjson_filepath, &:readline)).to include('title', 'description')
    end

    context 'when validate_import_decompressed_archive_size feature flag is enabled' do
      before do
        stub_feature_flags(validate_import_decompressed_archive_size: true)
      end

      it 'performs decompressed file size validation' do
        expect_next_instance_of(Gitlab::ImportExport::DecompressedArchiveSizeValidator) do |validator|
          expect(validator).to receive(:valid?).and_return(true)
        end

        subject.execute
      end
    end

    context 'when validate_import_decompressed_archive_size feature flag is disabled' do
      before do
        stub_feature_flags(validate_import_decompressed_archive_size: false)
      end

      it 'does not perform decompressed file size validation' do
        expect(Gitlab::ImportExport::DecompressedArchiveSizeValidator).not_to receive(:new)

        subject.execute
      end
    end

    context 'when dir is not in tmpdir' do
      subject { described_class.new(dir: '/etc', filename: 'filename') }

      it 'raises an error' do
        expect { subject.execute }.to raise_error(described_class::ServiceError, 'Invalid target directory')
      end
    end

    context 'when compressed file is a symlink' do
      let_it_be(:symlink) { File.join(tmpdir, 'symlink.gz') }

      before do
        FileUtils.ln_s(File.join(tmpdir, gz_filename), symlink)
      end

      subject { described_class.new(dir: tmpdir, filename: 'symlink.gz') }

      it 'raises an error and removes the file' do
        expect { subject.execute }.to raise_error(described_class::ServiceError, 'Invalid file')

        expect(File.exist?(symlink)).to eq(false)
      end
    end

    context 'when decompressed file is a symlink' do
      let_it_be(:symlink) { File.join(tmpdir, 'symlink') }

      before do
        FileUtils.ln_s(File.join(tmpdir, ndjson_filename), symlink)

        subject.instance_variable_set(:@decompressed_filepath, symlink)
      end

      subject { described_class.new(dir: tmpdir, filename: gz_filename) }

      it 'raises an error and removes the file' do
        expect { subject.execute }.to raise_error(described_class::ServiceError, 'Invalid file')

        expect(File.exist?(symlink)).to eq(false)
      end
    end
  end
end
