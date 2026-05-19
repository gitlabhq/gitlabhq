# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::Offline::Imports::MetadataFileReader, feature_category: :importers do
  describe '#read' do
    let(:configuration) { build(:import_offline_configuration) }

    let(:metadata) do
      {
        instance_version: '19.0.0',
        instance_enterprise: true,
        export_prefix: configuration.export_prefix,
        source_hostname: 'https://gitlab.example.com'
      }
    end

    let(:tmpdir) { Dir.mktmpdir }
    let(:reader) { described_class.new(configuration) }
    let(:file_download_service) { instance_double(BulkImports::FileDownloadService, execute: true) }
    let(:file_decompression_service) { instance_double(BulkImports::FileDecompressionService, execute: true) }

    before do
      allow(Dir).to receive(:mktmpdir).with(described_class::TMPDIR_SEGMENT).and_return(tmpdir)
      allow(BulkImports::FileDownloadService).to receive(:new).and_return(file_download_service)
      allow(BulkImports::FileDecompressionService).to receive(:new).and_return(file_decompression_service)

      File.write(File.join(tmpdir, described_class::METADATA_FILENAME), metadata.to_json)
    end

    it 'returns the parsed metadata' do
      expect(reader.read).to eq(metadata)
    end

    it 'downloads the compressed metadata file from object storage' do
      expect(BulkImports::FileDownloadService).to receive(:new).with(
        tmpdir: tmpdir,
        filename: described_class::COMPRESSED_METADATA_FILENAME,
        file_download_strategy: an_instance_of(
          Import::Offline::Imports::ObjectStorageFileDownloadStrategy
        )
      ).and_return(file_download_service)

      expect(file_download_service).to receive(:execute)

      reader.read
    end

    it 'decompresses the metadata file' do
      expect(BulkImports::FileDecompressionService).to receive(:new).with(
        tmpdir: tmpdir,
        filename: described_class::COMPRESSED_METADATA_FILENAME
      ).and_return(file_decompression_service)

      expect(file_decompression_service).to receive(:execute)

      reader.read
    end

    it 'removes the temp directory after execution' do
      reader.read

      expect(Dir.exist?(tmpdir)).to be(false)
    end

    context 'when the instance version is invalid' do
      let(:metadata) { super().merge(instance_version: 'not-a-version') }

      it 'raises an UnsupportedVersionError' do
        expect { reader.read }.to raise_error(described_class::UnsupportedVersionError, 'Invalid source version')
      end
    end

    context 'when the instance version is below the minimum supported version' do
      let(:metadata) { super().merge(instance_version: '18.11.0') }

      it 'raises an UnsupportedVersionError' do
        expect { reader.read }.to raise_error(
          described_class::UnsupportedVersionError,
          "Unsupported GitLab version. The minimum supported version is '#{described_class::MIN_SUPPORTED_VERSION}'."
        )
      end
    end

    context 'when the metadata file contains null JSON' do
      before do
        File.write(File.join(tmpdir, described_class::METADATA_FILENAME), 'null')
      end

      it 'raises a MetadataParseError' do
        expect { reader.read }.to raise_error(described_class::MetadataParseError, 'Failed to parse metadata')
      end
    end

    context 'when the metadata file contains invalid JSON' do
      before do
        File.write(File.join(tmpdir, described_class::METADATA_FILENAME), 'not valid json')
      end

      it 'raises a MetadataParseError' do
        expect { reader.read }.to raise_error(described_class::MetadataParseError, 'Failed to parse metadata')
      end
    end

    context 'when the metadata file is empty' do
      before do
        File.write(File.join(tmpdir, described_class::METADATA_FILENAME), '')
      end

      it 'raises a MetadataParseError' do
        expect { reader.read }.to raise_error(described_class::MetadataParseError, 'Failed to parse metadata')
      end
    end

    context 'when the download fails' do
      before do
        allow(file_download_service).to receive(:execute).and_raise(
          Import::BulkImports::FileDownloadStrategy::ServiceError, 'Download failed'
        )
      end

      it 'propagates the error' do
        expect { reader.read }.to raise_error(Import::BulkImports::FileDownloadStrategy::ServiceError)
      end

      it 'removes the temp directory' do
        expect { reader.read }.to raise_error(Import::BulkImports::FileDownloadStrategy::ServiceError)

        expect(Dir.exist?(tmpdir)).to be(false)
      end
    end
  end
end
