# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::Offline::Imports::ObjectStorageFileDownloadStrategy, feature_category: :importers do
  let(:object_key) { 'exports/project_1/labels.ndjson.gz' }
  let(:configuration) { build(:import_offline_configuration, :aws_s3) }
  let(:import_logger) { instance_double(BulkImports::Logger, info: nil, warn: nil) }
  let(:strategy) { described_class.new(offline_configuration: configuration, object_key: object_key) }

  before do
    allow(BulkImports::Logger).to receive(:build).and_return(import_logger)
  end

  describe '#validate!' do
    subject(:validate) { strategy.validate! }

    context 'when url is valid' do
      it 'does not raise an error' do
        expect { validate }.not_to raise_error
      end
    end

    context 'when url is not valid' do
      it 'raises an error' do
        stub_application_setting(deny_all_requests_except_allowed?: true)

        expect { validate }.to raise_error(Gitlab::HTTP_V2::UrlBlocker::BlockedUrlError)
      end
    end
  end

  describe '#download_file' do
    let(:filename) { 'labels.ndjson.gz' }
    let(:tmpdir) { Dir.mktmpdir }
    let(:filepath) { File.join(tmpdir, filename) }
    let(:storage_client) { instance_double(Import::Clients::ObjectStorage) }
    let(:first_chunk) { "\x1F\x8B\x08\x00".b }
    let(:second_chunk) { "file content".b }

    subject(:download_file) { strategy.download_file(filepath) }

    before do
      allow(Import::Clients::ObjectStorage).to receive(:new).and_return(storage_client)
      allow(storage_client).to receive(:stream).with(object_key)
        .and_yield(first_chunk, 0, 16).and_yield(second_chunk, 0, 16)

      stub_application_setting(bulk_import_max_download_file_size: 5120)
    end

    after do
      FileUtils.rm_rf(tmpdir)
    end

    it 'downloads the file' do
      download_file

      expect(File.exist?(filepath)).to be(true)
      expect(File.read(filepath, mode: 'rb')).to eq("#{first_chunk}#{second_chunk}")
    end

    context 'when first chunk does not have gzip magic bytes' do
      let(:first_chunk) { "not gzip content".b }

      it 'raises an error' do
        expect { download_file }.to raise_error(described_class::ServiceError, 'Invalid content type')
      end
    end

    context 'when file size exceeds the limit' do
      before do
        stub_application_setting(bulk_import_max_download_file_size: 0.000001)
      end

      it 'raises an error' do
        expect { download_file }.to raise_error(described_class::ServiceError, /File size .* exceeds limit of/)
      end
    end

    context 'when size is equals the file size limit' do
      let(:chunk) { "\x1F\x8B".b + ('x' * (1.megabyte - 2)) }

      before do
        stub_application_setting(bulk_import_max_download_file_size: 1)
        allow(storage_client).to receive(:stream).with(object_key).and_yield(chunk, 0, chunk.bytesize)
      end

      it 'does not raise an error' do
        expect { download_file }.not_to raise_error
      end
    end

    context 'when download fails with a Fog error' do
      before do
        allow(storage_client).to receive(:stream).with(object_key).and_raise(
          Import::Clients::ObjectStorage::DownloadError, 'Object storage download failed: connection refused'
        )
      end

      it 'cleans up the file and raises an error' do
        expect { download_file }.to raise_error(Import::Clients::ObjectStorage::DownloadError)

        expect(File.exist?(filepath)).to be(false)
      end
    end

    context 'when download fails with a standard error' do
      before do
        allow(storage_client).to receive(:stream).with(object_key).and_raise(StandardError, 'unexpected failure')
      end

      it 'cleans up the file and re-raises' do
        expect { download_file }.to raise_error(StandardError, 'unexpected failure')

        expect(File.exist?(filepath)).to be(false)
      end
    end

    context 'when dir path is being traversed' do
      let(:tmpdir) { File.join(Dir.mktmpdir('bulk_imports'), 'test', '..') }

      it 'raises an error' do
        expect { download_file }.to raise_error(
          Gitlab::PathTraversal::PathTraversalAttackError,
          'Invalid path'
        )
      end
    end

    context 'when file is a symlink' do
      let(:filename) { 'symlink' }
      let(:symlink) { File.join(tmpdir, filename) }
      let(:linked_filename) { 'file_download_service_spec' }

      before do
        FileUtils.ln_s(File.join(tmpdir, linked_filename), symlink, force: true)
      end

      it 'raises an error and removes the file' do
        expect { download_file }.to raise_error(
          Import::BulkImports::FileDownloadStrategy::ServiceError,
          'Invalid downloaded file'
        )

        expect(File.exist?(symlink)).to be(false)
      end
    end

    context 'when file shares multiple hard links' do
      let(:filename) { 'hard_link' }
      let(:hard_link) { File.join(tmpdir, filename) }

      before do
        existing_file = File.join(Dir.mktmpdir, filename)
        FileUtils.touch(existing_file)
        FileUtils.link(existing_file, hard_link)
      end

      it 'raises an error and removes the file' do
        expect { download_file }.to raise_error(
          Import::BulkImports::FileDownloadStrategy::ServiceError,
          'Invalid downloaded file'
        )

        expect(File.exist?(hard_link)).to be(false)
      end
    end
  end

  describe '#log_and_raise_error' do
    let(:import_logger) { instance_double(BulkImports::Logger) }

    it 'includes provider and object key in logs', :aggregate_failures do
      message = 'something went wrong'

      expect(import_logger).to receive(:warn).with({
        message: message,
        provider: configuration.provider,
        object_key: object_key
      })

      expect { strategy.log_and_raise_error(message) }.to raise_error(described_class::ServiceError, message)
    end
  end
end
