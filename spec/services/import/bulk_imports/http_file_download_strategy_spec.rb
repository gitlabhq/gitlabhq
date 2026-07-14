# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::BulkImports::HttpFileDownloadStrategy, feature_category: :importers do
  let_it_be(:bulk_import) { build_stubbed(:bulk_import, :with_configuration) }
  let_it_be(:entity) { build_stubbed(:bulk_import_entity, :with_portable, bulk_import: bulk_import) }
  let_it_be_with_reload(:context) { BulkImports::Pipeline::Context.new(build_stubbed(:bulk_import_tracker, entity: entity)) }
  let(:import_logger) { instance_double(BulkImports::Logger, info: nil, warn: nil) }

  let(:strategy) do
    described_class.new(
      context: context,
      relative_url: '/test'
    )
  end

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
        stub_application_setting(allow_local_requests_from_web_hooks_and_services: false)

        allow(context).to receive(:configuration).and_return(
          instance_double(BulkImports::Configuration, url: 'https://localhost', access_token: 'token')
        )

        expect { validate }.to raise_error(Gitlab::HTTP_V2::UrlBlocker::BlockedUrlError)
      end
    end
  end

  describe '#download_file' do
    let(:filename) { 'file_download_service_spec' }
    let(:tmpdir) { Dir.mktmpdir }
    let(:filepath) { File.join(tmpdir, filename) }
    let(:content_type) { 'application/octet-stream' }
    let(:content_disposition) { nil }

    let(:headers) do
      {
        'content-type' => content_type,
        'content-disposition' => content_disposition
      }
    end

    let(:chunk_code) { 200 }
    let(:chunk_content) { 'some chunk context' }
    let(:chunk_size) { 100 }
    let(:chunk_double) do
      double('chunk', # rubocop:disable RSpec/VerifiedDoubles -- size is delegated on HTTParty::ResponseFragment
        size: chunk_size,
        code: chunk_code,
        http_response: instance_double(Net::HTTPResponse, to_hash: headers),
        to_s: chunk_content
      )
    end

    subject(:download_file) { strategy.download_file(filepath) }

    before do
      allow_next_instance_of(BulkImports::Clients::HTTP) do |client|
        allow(client).to receive(:stream).and_yield(chunk_double)
      end

      allow_next_instance_of(described_class) do |strategy|
        allow(strategy).to receive(:response_headers).and_return(headers)
      end

      stub_application_setting(bulk_import_max_download_file_size: 5120) # 5 GiB
    end

    after do
      FileUtils.rm_rf(tmpdir)
    end

    shared_examples 'downloads file' do
      it 'downloads file', :aggregate_failures do
        download_file

        expect(File.exist?(filepath)).to be(true)
        expect(File.read(filepath)).to include('chunk')
      end
    end

    include_examples 'downloads file'

    context 'when content-type is application/gzip' do
      let(:content_type) { 'application/gzip' }

      include_examples 'downloads file'
    end

    context 'when content-type is not valid' do
      let(:content_type) { 'invalid' }

      it 'logs and raises an error' do
        expect(import_logger).to receive(:warn).once.with({
          message: 'Invalid content type',
          response_code: chunk_code,
          response_headers: headers,
          last_chunk_context: 'some chunk context'
        })

        expect { download_file }.to raise_error(described_class::ServiceError, 'Invalid content type')
      end
    end

    context 'when content types are specified' do
      let(:strategy) do
        described_class.new(
          context: context,
          relative_url: '/test',
          allowed_content_types: ['application/gzip']
        )
      end

      it 'logs and raises an error for invalid content types' do
        expect(import_logger).to receive(:warn).once.with({
          message: 'Invalid content type',
          response_code: chunk_code,
          response_headers: headers,
          last_chunk_context: 'some chunk context'
        })

        expect { download_file }.to raise_error(described_class::ServiceError, 'Invalid content type')
      end
    end

    context 'when size exceeds limit' do
      let(:chunk_size) { 40.gigabytes }

      it 'raises an error' do
        expect { download_file }.to raise_error(
          described_class::ServiceError,
          'File size 40 GiB exceeds limit of 5 GiB'
        )
      end

      context 'when file size limit is overridden' do
        before do
          allow(context).to receive(:override_file_size_limit?).and_return(true)
        end

        it 'does not raise an error' do
          expect { download_file }.not_to raise_error
        end

        it 'logs download exceeding file size limit' do
          expect(import_logger).to receive(:info).with(
            a_hash_including(message: 'File size allowed to exceed download file size limit')
          )

          download_file
        end
      end
    end

    context 'when size is equal to the file size limit' do
      let(:chunk_size) { 5.gigabytes }

      it 'does not raise an error' do
        expect { download_file }.not_to raise_error
      end

      context 'when file size limit is overridden' do
        before do
          allow(context).to receive(:override_file_size_limit?).and_return(true)
        end

        it 'does not log downloads not exceeding default file size limits' do
          expect(import_logger).not_to receive(:info)

          download_file
        end
      end
    end

    context 'when the instance does not have a file size limit' do
      let(:chunk_size) { 40.gigabytes }

      before do
        stub_application_setting(bulk_import_max_download_file_size: 0)
      end

      it 'does not raise an error' do
        expect { download_file }.not_to raise_error
      end

      context 'when file size limit is overridden' do
        before do
          allow(context).to receive(:override_file_size_limit?).and_return(true)
        end

        it 'does not log download file size' do
          expect(import_logger).not_to receive(:info)

          download_file
        end
      end
    end

    context 'when chunk code is not 200' do
      let(:chunk_code) { 404 }

      it 'raises an error' do
        expect { download_file }.to raise_error(described_class::ServiceError, 'File download error 404')
      end

      context 'when chunk code is retriable' do
        let(:chunk_code) { 502 }

        it 'raises a retriable error' do
          expect { download_file }.to raise_error(
            BulkImports::NetworkError,
            'Error downloading file from /test. Error code: 502'
          )
        end
      end

      context 'when chunk code is redirection' do
        let(:chunk_code) { 303 }

        it 'does not write a redirection chunk' do
          expect { download_file }.not_to raise_error

          expect(File.read(filepath)).not_to include('redirection')
        end

        context 'when redirection chunk appears at a later stage of the download' do
          it 'raises an error' do
            # rubocop:disable RSpec/VerifiedDoubles -- size is delegated on HTTParty::ResponseFragment
            another_chunk_double = double('another redirection', size: 1000, code: 303)
            data_chunk = double(
              'data chunk', size: 1000, code: 200,
              http_response: instance_double(Net::HTTPResponse, to_hash: {})
            )
            # rubocop:enable RSpec/VerifiedDoubles

            allow_next_instance_of(BulkImports::Clients::HTTP) do |client|
              allow(client)
                .to receive(:stream)
                .and_yield(chunk_double)
                .and_yield(data_chunk)
                .and_yield(another_chunk_double)
            end

            expect { download_file }.to raise_error(described_class::ServiceError, 'File download error 303')
          end
        end
      end
    end

    describe 'remote content validation' do
      context 'on redirect chunk' do
        let(:chunk_code) { 303 }

        it 'does not run content type & validation' do
          expect(strategy).not_to receive(:validate_content_type)

          download_file
        end
      end

      context 'when there is one data chunk' do
        it 'validates content type' do
          expect(strategy).to receive(:validate_content_type)

          download_file
        end
      end

      context 'when there are multiple data chunks' do
        it 'validates content type only once' do
          data_chunk = double( # rubocop:disable RSpec/VerifiedDoubles -- size is delegated on HTTParty::ResponseFragment
            'data chunk',
            size: 1000,
            code: 200,
            http_response: instance_double(Net::HTTPResponse, to_hash: {})
          )

          allow_next_instance_of(BulkImports::Clients::HTTP) do |client|
            allow(client)
              .to receive(:stream)
              .and_yield(chunk_double)
              .and_yield(data_chunk)
          end

          expect(strategy).to receive(:validate_content_type).once

          download_file
        end
      end
    end

    context 'when logging a chunk context' do
      using RSpec::Parameterized::TableSyntax

      let(:chunk_size) { 40.gigabytes }

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

          expect { download_file }.to raise_error(
            described_class::ServiceError,
            'File size 40 GiB exceeds limit of 5 GiB'
          )
        end
      end
    end

    context 'when the path is being traversed' do
      let(:tmpdir) { File.join(Dir.mktmpdir('bulk_imports'), 'test', '..') }

      it 'raises an error' do
        expect { download_file }.to raise_error(Gitlab::PathTraversal::PathTraversalAttackError, 'Invalid path')
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

    it 'includes response context in logs', :aggregate_failures do
      message = 'something went wrong'

      expect(import_logger).to receive(:warn).with({
        message: message,
        response_code: anything,
        response_headers: anything,
        last_chunk_context: anything
      })

      expect { strategy.log_and_raise_error(message) }.to raise_error(described_class::ServiceError, message)
    end
  end
end
