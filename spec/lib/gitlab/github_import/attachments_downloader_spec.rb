# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::AttachmentsDownloader do
  subject(:downloader) { described_class.new(file_url) }

  let_it_be(:file_url) { 'https://example.com/avatar.png' }
  let_it_be(:content_type) { 'application/octet-stream' }

  let(:content_length) { 1000 }
  let(:chunk_double) { instance_double(HTTParty::ResponseFragment, code: 200) }
  let(:headers_double) do
    instance_double(
      HTTParty::Response,
      code: 200,
      success?: true,
      parsed_response: {},
      headers: {
        'content-length' => content_length,
        'content-type' => content_type
      }
    )
  end

  describe '#perform' do
    before do
      allow(Gitlab::HTTP).to receive(:perform_request)
        .with(Net::HTTP::Get, file_url, stream_body: true).and_yield(chunk_double)
      allow(Gitlab::HTTP).to receive(:perform_request)
        .with(Net::HTTP::Head, file_url, {}).and_return(headers_double)
    end

    context 'when file valid' do
      it 'downloads file' do
        file = downloader.perform

        expect(File.exist?(file.path)).to eq(true)
      end
    end

    context 'when filename is malicious' do
      let_it_be(:file_url) { 'https://example.com/ava%2F..%2Ftar.png' }

      it 'raises expected exception' do
        expect { downloader.perform }.to raise_exception(
          Gitlab::Utils::PathTraversalAttackError,
          'Invalid path'
        )
      end
    end

    context 'when file size exceeds limit' do
      let(:content_length) { 26.megabytes }

      it 'raises expected exception' do
        expect { downloader.perform }.to raise_exception(
          Gitlab::GithubImport::AttachmentsDownloader::DownloadError,
          'File size 26 MB exceeds limit of 25 MB'
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
