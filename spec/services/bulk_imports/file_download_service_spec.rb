# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::FileDownloadService, feature_category: :importers do
  describe '#execute' do
    let_it_be(:allowed_content_types) { %w[application/gzip application/octet-stream] }
    let_it_be(:file_size_limit) { 5.gigabytes }
    let_it_be(:config) { build(:bulk_import_configuration) }
    let_it_be(:content_type) { 'application/octet-stream' }
    let_it_be(:content_disposition) { nil }
    let_it_be(:filename) { 'file_download_service_spec' }
    let_it_be(:tmpdir) { Dir.mktmpdir }
    let_it_be(:filepath) { File.join(tmpdir, filename) }

    let(:headers) do
      {
        'content-type' => content_type,
        'content-disposition' => content_disposition
      }
    end

    let(:chunk_code) { 200 }
    let(:chunk_content) { 'some chunk context' }
    let(:chunk_double) do
      double('chunk', size: 100, code: chunk_code, http_response: double(to_hash: headers), to_s: chunk_content)
    end

    subject(:service) do
      described_class.new(
        configuration: config,
        relative_url: '/test',
        tmpdir: tmpdir,
        filename: filename,
        file_size_limit: file_size_limit,
        allowed_content_types: allowed_content_types
      )
    end

    before do
      allow_next_instance_of(BulkImports::Clients::HTTP) do |client|
        allow(client).to receive(:stream).and_yield(chunk_double)
      end

      allow(service).to receive(:response_headers).and_return(headers)
    end

    shared_examples 'downloads file' do
      it 'downloads file' do
        subject.execute

        expect(File.exist?(filepath)).to eq(true)
        expect(File.read(filepath)).to include('chunk')
      end
    end

    include_examples 'downloads file'

    context 'when content-type is application/gzip' do
      let_it_be(:content_type) { 'application/gzip' }

      include_examples 'downloads file'
    end

    context 'when url is not valid' do
      it 'raises an error' do
        stub_application_setting(allow_local_requests_from_web_hooks_and_services: false)

        double = instance_double(BulkImports::Configuration, url: 'https://localhost', access_token: 'token')
        service = described_class.new(
          configuration: double,
          relative_url: '/test',
          tmpdir: tmpdir,
          filename: filename,
          file_size_limit: file_size_limit,
          allowed_content_types: allowed_content_types
        )

        expect { service.execute }.to raise_error(Gitlab::HTTP_V2::UrlBlocker::BlockedUrlError)
      end
    end

    context 'when content-type is not valid' do
      let(:content_type) { 'invalid' }
      let(:import_logger) { instance_double(BulkImports::Logger) }

      before do
        allow(BulkImports::Logger).to receive(:build).and_return(import_logger)
        allow(import_logger).to receive(:warn)
      end

      it 'logs and raises an error' do
        expect(import_logger).to receive(:warn).once.with(
          message: 'Invalid content type',
          response_code: chunk_code,
          response_headers: headers,
          last_chunk_context: 'some chunk context'
        )

        expect { subject.execute }.to raise_error(described_class::ServiceError, 'Invalid content type')
      end
    end

    context 'when file size is not valid' do
      context 'when size exceeds limit' do
        let(:file_size_limit) { 1 }

        it 'raises an error' do
          expect { subject.execute }.to raise_error(
            described_class::ServiceError,
            'File size 100 B exceeds limit of 1 B'
          )
        end
      end
    end

    context 'when size is equals the file size limit' do
      let(:file_size_limit) { 100 }

      it 'does not raise an error' do
        expect { subject.execute }.not_to raise_error
      end
    end

    context 'when chunk code is not 200' do
      let(:chunk_code) { 404 }

      it 'raises an error' do
        expect { subject.execute }.to raise_error(
          described_class::ServiceError,
          'File download error 404'
        )
      end

      context 'when chunk code is retriable' do
        let(:chunk_code) { 502 }

        it 'raises a retriable error' do
          expect { subject.execute }.to raise_error(
            BulkImports::NetworkError,
            'Error downloading file from /test. Error code: 502'
          )
        end
      end

      context 'when chunk code is redirection' do
        let(:chunk_code) { 303 }

        it 'does not write a redirection chunk' do
          expect { subject.execute }.not_to raise_error

          expect(File.read(filepath)).not_to include('redirection')
        end

        context 'when redirection chunk appears at a later stage of the download' do
          it 'raises an error' do
            another_chunk_double = double('another redirection', size: 1000, code: 303)
            data_chunk = double('data chunk', size: 1000, code: 200, http_response: double(to_hash: {}))

            allow_next_instance_of(BulkImports::Clients::HTTP) do |client|
              allow(client)
                .to receive(:stream)
                .and_yield(chunk_double)
                .and_yield(data_chunk)
                .and_yield(another_chunk_double)
            end

            expect { subject.execute }.to raise_error(
              described_class::ServiceError,
              'File download error 303'
            )
          end
        end
      end
    end

    describe 'remote content validation' do
      context 'on redirect chunk' do
        let(:chunk_code) { 303 }

        it 'does not run content type & validation' do
          expect(service).not_to receive(:validate_content_type)

          service.execute
        end
      end

      context 'when there is one data chunk' do
        it 'validates content type' do
          expect(service).to receive(:validate_content_type)

          service.execute
        end
      end

      context 'when there are multiple data chunks' do
        it 'validates content type only once' do
          data_chunk = double(
            'data chunk',
            size: 1000,
            code: 200,
            http_response: double(to_hash: {})
          )

          allow_next_instance_of(BulkImports::Clients::HTTP) do |client|
            allow(client)
              .to receive(:stream)
              .and_yield(chunk_double)
              .and_yield(data_chunk)
          end

          expect(service).to receive(:validate_content_type).once

          service.execute
        end
      end
    end

    context 'when file is a symlink' do
      let_it_be(:symlink) { File.join(tmpdir, 'symlink') }

      before do
        FileUtils.ln_s(File.join(tmpdir, filename), symlink, force: true)
      end

      subject do
        described_class.new(
          configuration: config,
          relative_url: '/test',
          tmpdir: tmpdir,
          filename: 'symlink',
          file_size_limit: file_size_limit,
          allowed_content_types: allowed_content_types
        )
      end

      it 'raises an error and removes the file' do
        expect { subject.execute }.to raise_error(
          described_class::ServiceError,
          'Invalid downloaded file'
        )

        expect(File.exist?(symlink)).to eq(false)
      end
    end

    context 'when file shares multiple hard links' do
      let_it_be(:hard_link) { File.join(tmpdir, 'hard_link') }

      before do
        existing_file = File.join(Dir.mktmpdir, filename)
        FileUtils.touch(existing_file)
        FileUtils.link(existing_file, hard_link)
      end

      subject do
        described_class.new(
          configuration: config,
          relative_url: '/test',
          tmpdir: tmpdir,
          filename: 'hard_link',
          file_size_limit: file_size_limit,
          allowed_content_types: allowed_content_types
        )
      end

      it 'raises an error and removes the file' do
        expect { subject.execute }.to raise_error(
          described_class::ServiceError,
          'Invalid downloaded file'
        )

        expect(File.exist?(hard_link)).to eq(false)
      end
    end

    context 'when dir is not in tmpdir' do
      subject do
        described_class.new(
          configuration: config,
          relative_url: '/test',
          tmpdir: '/etc',
          filename: filename,
          file_size_limit: file_size_limit,
          allowed_content_types: allowed_content_types
        )
      end

      it 'raises an error' do
        expect { subject.execute }.to raise_error(
          StandardError,
          'path /etc is not allowed'
        )
      end
    end

    context 'when dir path is being traversed' do
      subject do
        described_class.new(
          configuration: config,
          relative_url: '/test',
          tmpdir: File.join(Dir.mktmpdir('bulk_imports'), 'test', '..'),
          filename: filename,
          file_size_limit: file_size_limit,
          allowed_content_types: allowed_content_types
        )
      end

      it 'raises an error' do
        expect { subject.execute }.to raise_error(
          Gitlab::PathTraversal::PathTraversalAttackError,
          'Invalid path'
        )
      end
    end

    context 'when using the remote filename' do
      let_it_be(:filename) { nil }

      context 'when no filename is given' do
        it 'raises an error when the filename is not provided in the request header' do
          expect { subject.execute }.to raise_error(
            described_class::ServiceError,
            'Remote filename not provided in content-disposition header'
          )
        end
      end

      context 'with a given filename' do
        let_it_be(:content_disposition) { 'filename="avatar.png"' }

        it 'uses the given filename' do
          expect(subject.execute).to eq(File.join(tmpdir, "avatar.png"))
        end
      end

      context 'when the filename is a path' do
        let_it_be(:content_disposition) { 'filename="../../avatar.png"' }

        it 'raises an error when the filename is not provided in the request header' do
          expect(subject.execute).to eq(File.join(tmpdir, "avatar.png"))
        end
      end

      context 'when the filename is longer the the limit' do
        let_it_be(:content_disposition) { 'filename="../../xxx.b"' }

        before do
          stub_const('BulkImports::FileDownloads::FilenameFetch::FILENAME_SIZE_LIMIT', 1)
        end

        it 'raises an error when the filename is not provided in the request header' do
          expect(subject.execute).to eq(File.join(tmpdir, "x.b"))
        end
      end
    end

    context 'when logging a chunk context' do
      using RSpec::Parameterized::TableSyntax

      let(:file_size_limit) { 1 }
      let(:import_logger) { instance_double(BulkImports::Logger) }

      before do
        allow(BulkImports::Logger).to receive(:build).and_return(import_logger)
        allow(import_logger).to receive(:warn)
      end

      where(:input, :output) do
        String.new("\x8d\x21\x3f\xad\x76", encoding: 'UTF-8') | "�!?�v"
        String.new("\x1F\x8B\b\x00\x1F", encoding: 'ASCII-8BIT') | "\u001F�\b\u0000\u001F"
      end

      with_them do
        let(:chunk_content) { input }

        it 'scrubs non-printable characters from the chunk' do
          expect(import_logger).to receive(:warn).once.with(
            a_hash_including(last_chunk_context: output)
          )

          expect { service.execute }.to raise_error(
            described_class::ServiceError,
            'File size 100 B exceeds limit of 1 B'
          )
        end
      end
    end
  end
end
