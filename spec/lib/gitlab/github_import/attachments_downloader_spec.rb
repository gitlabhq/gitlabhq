# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::AttachmentsDownloader, feature_category: :importers do
  subject(:downloader) { described_class.new(file_url) }

  let_it_be(:file_url) { 'https://example.com/avatar.png' }
  let_it_be(:content_type) { 'application/octet-stream' }

  let(:chunk_double) { instance_double(HTTParty::ResponseFragment, code: 200) }

  describe '#perform' do
    before do
      allow(Gitlab::HTTP).to receive(:perform_request)
        .with(Net::HTTP::Get, file_url, stream_body: true).and_yield(chunk_double)
    end

    context 'when file valid' do
      it 'downloads file' do
        file = downloader.perform

        expect(File.exist?(file.path)).to eq(true)
      end
    end

    context 'when file shares multiple hard links' do
      let(:tmpdir) { Dir.mktmpdir }
      let(:hard_link) { File.join(tmpdir, 'hard_link') }

      before do
        existing_file = File.join(tmpdir, 'file.txt')
        FileUtils.touch(existing_file)
        FileUtils.link(existing_file, hard_link)
        allow(downloader).to receive(:filepath).and_return(hard_link)
      end

      it 'raises expected exception' do
        expect(Gitlab::Utils::FileInfo).to receive(:linked?).with(hard_link).and_call_original
        expect { downloader.perform }.to raise_exception(
          described_class::DownloadError,
          'Invalid downloaded file'
        )
      end
    end

    context 'when filename is malicious' do
      let_it_be(:file_url) { 'https://example.com/ava%2F..%2Ftar.png' }

      it 'raises expected exception' do
        expect { downloader.perform }.to raise_exception(
          Gitlab::PathTraversal::PathTraversalAttackError,
          'Invalid path'
        )
      end
    end

    context 'when file size exceeds limit' do
      subject(:downloader) { described_class.new(file_url, file_size_limit: 1.byte) }

      it 'raises expected exception' do
        expect { downloader.perform }.to raise_exception(
          Gitlab::GithubImport::AttachmentsDownloader::DownloadError,
          'File size 57 B exceeds limit of 1 B'
        )
      end
    end

    context 'when file name length exceeds limit' do
      before do
        stub_const('BulkImports::FileDownloads::FilenameFetch::FILENAME_SIZE_LIMIT', 2)
      end

      it 'chops filename' do
        file = downloader.perform

        expect(File.exist?(file.path)).to eq(true)
        expect(File.basename(file)).to eq('av.png')
      end
    end

    context 'when chunk download returns a redirect' do
      let(:chunk_double) { instance_double(HTTParty::ResponseFragment, code: 302, http_response: {}) }

      it 'skips the redirect and continues' do
        allow(Gitlab::HTTP).to receive(:perform_request)
          .with(Net::HTTP::Get, file_url, stream_body: true).and_yield(chunk_double)

        file = downloader.perform

        expect(File.exist?(file.path)).to eq(true)
      end
    end

    context 'when chunk download returns an error' do
      let(:chunk_double) { instance_double(HTTParty::ResponseFragment, code: 500, http_response: {}) }

      it 'raises expected exception' do
        allow(Gitlab::HTTP).to receive(:perform_request)
          .with(Net::HTTP::Get, file_url, stream_body: true).and_yield(chunk_double)

        expect { downloader.perform }.to raise_exception(
          Gitlab::GithubImport::AttachmentsDownloader::DownloadError,
          "Error downloading file from #{file_url}. Error code: #{chunk_double.code}"
        )
      end
    end

    context 'when attachment is behind a github asset endpoint' do
      let(:file_url) { "https://github.com/test/project/assets/142635249/4b9f9c90-f060-4845-97cf-b24c558bcb11" }
      let(:redirect_url) { "https://github-production-user-asset-6210df.s3.amazonaws.com/142635249/740edb05293e.jpg" }
      let(:sample_response) do
        instance_double(HTTParty::Response, redirection?: true, headers: { location: redirect_url })
      end

      it 'gets redirection url' do
        expect(Gitlab::HTTP).to receive(:perform_request)
          .with(Net::HTTP::Get, file_url, { follow_redirects: false })
          .and_return sample_response

        expect(Gitlab::HTTP).to receive(:perform_request)
          .with(Net::HTTP::Get, redirect_url, stream_body: true).and_yield(chunk_double)

        file = downloader.perform

        expect(File.exist?(file.path)).to eq(true)
      end

      context 'when url is not a redirection' do
        let(:file_url) { "https://github.com/test/project/assets/142635249/4b9f9c90-f060-4845-97cf-b24c558bcb11.jpg" }

        let(:sample_response) do
          instance_double(HTTParty::Response, code: 200, redirection?: false)
        end

        before do
          allow(Gitlab::HTTP).to receive(:perform_request)
            .with(Net::HTTP::Get, file_url, { follow_redirects: false })
            .and_return sample_response
        end

        it 'queries with original file_url' do
          expect(Gitlab::HTTP).to receive(:perform_request)
            .with(Net::HTTP::Get, file_url, stream_body: true).and_yield(chunk_double)

          file = downloader.perform

          expect(File.exist?(file.path)).to eq(true)
        end
      end

      context 'when redirection url is not supported' do
        let(:redirect_url) { "https://https://github-production-user-asset-6210df.s3.amazonaws.com/142635249/740edb05293e.idk" }

        before do
          allow(Gitlab::HTTP).to receive(:perform_request)
            .with(Net::HTTP::Get, file_url, { follow_redirects: false })
            .and_return sample_response
        end

        it 'raises UnsupportedAttachmentError on unsupported extension' do
          expect { downloader.perform }.to raise_error(described_class::UnsupportedAttachmentError)
        end
      end
    end
  end

  describe '#delete' do
    let(:tmp_dir_path) { File.join(Dir.tmpdir, 'github_attachments_test') }
    let(:file) do
      downloader.mkdir_p(tmp_dir_path)
      file = File.open("#{tmp_dir_path}/test.txt", 'wb')
      file.write('foo')
      file.close
      file
    end

    before do
      allow(downloader).to receive(:filepath).and_return(file.path)
    end

    it 'removes file with parent folder' do
      downloader.delete
      expect(Dir.exist?(tmp_dir_path)).to eq false
    end
  end
end
