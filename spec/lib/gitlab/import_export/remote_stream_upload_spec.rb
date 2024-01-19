# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::ImportExport::RemoteStreamUpload do
  include StubRequests

  subject do
    described_class.new(
      download_url: download_url,
      upload_url: upload_url,
      options: {
        upload_method: upload_method,
        upload_content_type: upload_content_type
      }
    )
  end

  let(:download_url) { 'http://object-storage/file.txt' }
  let(:upload_url) { 'http://example.com/file.txt' }
  let(:upload_method) { :post }
  let(:upload_content_type) { 'text/plain' }

  describe '#execute' do
    context 'when download request and upload request return 200' do
      before do
        stub_application_setting(allow_local_requests_from_web_hooks_and_services: true)
        stub_application_setting(dns_rebinding_protection_enabled: false)
        stub_request(:get, download_url).to_return(status: 200, body: 'ABC', headers: { 'Content-Length' => 3 })
        stub_request(:post, upload_url)
      end

      it 'uploads the downloaded content' do
        subject.execute

        expect(
          a_request(:post, upload_url).with(
            body: 'ABC', headers: { 'Content-Length' => 3, 'Content-Type' => 'text/plain' }
          )
        ).to have_been_made
      end

      it 'calls the connection adapter twice with required args' do
        expect(Gitlab::HTTP_V2::NewConnectionAdapter)
          .to receive(:new).twice.with(instance_of(URI::HTTP), {
            allow_local_requests: true,
            dns_rebind_protection: false
          }).and_call_original

        subject.execute
      end
    end

    context 'when upload method is put' do
      let(:upload_method) { :put }

      it 'uploads using the put method' do
        stub_request(:get, download_url).to_return(status: 200, body: 'ABC', headers: { 'Content-Length' => 3 })
        stub_request(:put, upload_url)

        subject.execute

        expect(
          a_request(:put, upload_url).with(
            body: 'ABC', headers: { 'Content-Length' => 3, 'Content-Type' => 'text/plain' }
          )
        ).to have_been_made
      end
    end

    context 'when download request does not return 200' do
      it do
        stub_request(:get, download_url).to_return(status: 404)

        expect { subject.execute }.to raise_error(
          Gitlab::ImportExport::RemoteStreamUpload::StreamError,
          "Invalid response code while downloading file. Code: 404"
        )
      end
    end

    context 'when upload request does not returns 200' do
      it do
        stub_request(:get, download_url).to_return(status: 200, body: 'ABC', headers: { 'Content-Length' => 3 })
        stub_request(:post, upload_url).to_return(status: 403)

        expect { subject.execute }.to raise_error(
          Gitlab::ImportExport::RemoteStreamUpload::StreamError,
          "Invalid response code while uploading file. Code: 403"
        )
      end
    end

    context 'when download URL is a local address' do
      let(:download_url) { 'http://127.0.0.1/file.txt' }

      before do
        stub_request(:get, download_url)
        stub_request(:post, upload_url)
      end

      it 'raises error' do
        expect { subject.execute }.to raise_error(
          Gitlab::HTTP_V2::BlockedUrlError,
          "URL is blocked: Requests to localhost are not allowed"
        )
      end

      context 'when local requests are allowed' do
        before do
          stub_application_setting(allow_local_requests_from_web_hooks_and_services: true)
        end

        it 'raises does not error' do
          expect { subject.execute }.not_to raise_error
        end
      end
    end

    context 'when download URL is a local network' do
      let(:download_url) { 'http://172.16.0.0/file.txt' }

      before do
        stub_request(:get, download_url)
        stub_request(:post, upload_url)
      end

      it 'raises error' do
        expect { subject.execute }.to raise_error(
          Gitlab::HTTP_V2::BlockedUrlError,
          "URL is blocked: Requests to the local network are not allowed"
        )
      end

      context 'when local network requests are allowed' do
        before do
          stub_application_setting(allow_local_requests_from_web_hooks_and_services: true)
        end

        it 'raises does not error' do
          expect { subject.execute }.not_to raise_error
        end
      end
    end

    context 'when upload URL is a local address' do
      let(:upload_url) { 'http://127.0.0.1/file.txt' }

      before do
        stub_request(:get, download_url)
        stub_request(:post, upload_url)
      end

      it 'raises error' do
        stub_request(:get, download_url)

        expect { subject.execute }.to raise_error(
          Gitlab::HTTP_V2::BlockedUrlError,
          "URL is blocked: Requests to localhost are not allowed"
        )
      end

      context 'when local requests are allowed' do
        before do
          stub_application_setting(allow_local_requests_from_web_hooks_and_services: true)
        end

        it 'raises does not error' do
          expect { subject.execute }.not_to raise_error
        end
      end
    end

    context 'when upload URL it is a request to local network' do
      let(:upload_url) { 'http://172.16.0.0/file.txt' }

      before do
        stub_request(:get, download_url)
        stub_request(:post, upload_url)
      end

      it 'raises error' do
        expect { subject.execute }.to raise_error(
          Gitlab::HTTP_V2::BlockedUrlError,
          "URL is blocked: Requests to the local network are not allowed"
        )
      end

      context 'when local network requests are allowed' do
        before do
          stub_application_setting(allow_local_requests_from_web_hooks_and_services: true)
        end

        it 'raises does not error' do
          expect { subject.execute }.not_to raise_error
        end
      end
    end

    context 'when upload URL resolves to a local address' do
      let(:upload_url) { 'http://example.com/file.txt' }

      it 'raises error' do
        stub_request(:get, download_url)
        stub_full_request(upload_url, ip_address: '127.0.0.1', method: upload_method)

        expect { subject.execute }.to raise_error(
          Gitlab::HTTP_V2::BlockedUrlError,
          "URL is blocked: Requests to localhost are not allowed"
        )
      end
    end
  end

  describe Gitlab::ImportExport::RemoteStreamUpload::ChunkStream do
    describe 'StringIO#copy_stream compatibility' do
      it 'copies all chunks' do
        chunks = %w[ABC EFD].to_enum
        chunk_stream = described_class.new(chunks)
        new_stream = StringIO.new

        IO.copy_stream(chunk_stream, new_stream)
        new_stream.rewind

        expect(new_stream.read).to eq('ABCEFD')
      end

      context 'with chunks smaller and bigger than buffer size' do
        before do
          stub_const('Gitlab::ImportExport::RemoteStreamUpload::ChunkStream::DEFAULT_BUFFER_SIZE', 4)
        end

        it 'copies all chunks' do
          chunks = %w[A BC DEF GHIJ KLMNOPQ RSTUVWXYZ].to_enum
          chunk_stream = described_class.new(chunks)
          new_stream = StringIO.new

          IO.copy_stream(chunk_stream, new_stream)
          new_stream.rewind

          expect(new_stream.read).to eq('ABCDEFGHIJKLMNOPQRSTUVWXYZ')
        end
      end
    end
  end
end
