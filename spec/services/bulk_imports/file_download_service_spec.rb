# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::FileDownloadService do
  describe '#execute' do
    let_it_be(:config) { build(:bulk_import_configuration) }
    let_it_be(:content_type) { 'application/octet-stream' }
    let_it_be(:filename) { 'file_download_service_spec' }
    let_it_be(:tmpdir) { Dir.tmpdir }
    let_it_be(:filepath) { File.join(tmpdir, filename) }

    let(:chunk_double) { double('chunk', size: 1000, code: 200) }
    let(:response_double) do
      double(
        code: 200,
        success?: true,
        parsed_response: {},
        headers: {
          'content-length' => 100,
          'content-type' => content_type
        }
      )
    end

    subject { described_class.new(configuration: config, relative_url: '/test', dir: tmpdir, filename: filename) }

    before do
      allow_next_instance_of(BulkImports::Clients::HTTP) do |client|
        allow(client).to receive(:head).and_return(response_double)
        allow(client).to receive(:stream).and_yield(chunk_double)
      end
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
        service = described_class.new(configuration: double, relative_url: '/test', dir: tmpdir, filename: filename)

        expect { service.execute }.to raise_error(Gitlab::UrlBlocker::BlockedUrlError)
      end
    end

    context 'when content-type is not valid' do
      let(:content_type) { 'invalid' }

      it 'raises an error' do
        expect { subject.execute }.to raise_error(described_class::ServiceError, 'Invalid content type')
      end
    end

    context 'when content-length is not valid' do
      context 'when content-length exceeds limit' do
        before do
          stub_const("#{described_class}::FILE_SIZE_LIMIT", 1)
        end

        it 'raises an error' do
          expect { subject.execute }.to raise_error(described_class::ServiceError, 'Invalid content length')
        end
      end

      context 'when content-length is missing' do
        let(:response_double) { double(success?: true, headers: { 'content-type' => content_type }) }

        it 'raises an error' do
          expect { subject.execute }.to raise_error(described_class::ServiceError, 'Invalid content length')
        end
      end
    end

    context 'when partially downloaded file exceeds limit' do
      before do
        stub_const("#{described_class}::FILE_SIZE_LIMIT", 150)
      end

      it 'raises an error' do
        expect { subject.execute }.to raise_error(described_class::ServiceError, 'Invalid downloaded file')
      end
    end

    context 'when chunk code is not 200' do
      let(:chunk_double) { double('chunk', size: 1000, code: 307) }

      it 'raises an error' do
        expect { subject.execute }.to raise_error(described_class::ServiceError, 'File download error 307')
      end
    end

    context 'when file is a symlink' do
      let_it_be(:symlink) { File.join(tmpdir, 'symlink') }

      before do
        FileUtils.ln_s(File.join(tmpdir, filename), symlink)
      end

      subject { described_class.new(configuration: config, relative_url: '/test', dir: tmpdir, filename: 'symlink') }

      it 'raises an error and removes the file' do
        expect { subject.execute }.to raise_error(described_class::ServiceError, 'Invalid downloaded file')

        expect(File.exist?(symlink)).to eq(false)
      end
    end

    context 'when dir is not in tmpdir' do
      subject { described_class.new(configuration: config, relative_url: '/test', dir: '/etc', filename: filename) }

      it 'raises an error' do
        expect { subject.execute }.to raise_error(described_class::ServiceError, 'Invalid target directory')
      end
    end
  end
end
