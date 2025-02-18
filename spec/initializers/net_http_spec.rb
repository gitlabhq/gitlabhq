# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Net::Http patch', feature_category: :integrations do
  def gzip_compress(content)
    buffer = StringIO.new
    gzip = Zlib::GzipWriter.new(buffer)
    gzip.write(content)
    gzip.close
    buffer.string
  end

  def read_body(res, io)
    body = nil
    res.reading_body io, true do
      body = res.read_body
    end
    body
  end

  shared_examples 'logging behavior for decompressed content' do |size|
    it 'logs the decompressed content size' do
      expect(Gitlab::AppJsonLogger).to receive(:debug).with(message: 'net/http: response decompressed', size: size)

      res = Net::HTTPResponse.read_new(io)
      res.decode_content = true

      read_body(res, io)
    end
  end

  shared_examples 'no logging for decompressed content' do
    it 'does not log the decompressed content size' do
      expect(Gitlab::AppJsonLogger).not_to receive(:debug)

      res = Net::HTTPResponse.read_new(io)
      res.decode_content = true

      read_body(res, io)
    end
  end

  describe 'decompressing data' do
    let(:body) { 'Hello world!' }
    let(:io) do
      gzip_body = gzip_compress(body)
      response = <<~RESPONSE
        HTTP/1.1 200 OK
        Content-Encoding: gzip
        Content-Type: text/plain

        #{gzip_body}
      RESPONSE

      Net::BufferedIO.new(StringIO.new(response.force_encoding('ASCII-8BIT')))
    end

    context 'when decompressed content size exceeds the log threshold' do
      before do
        allow(Gitlab.config.gitlab).to receive(:log_decompressed_response_bytesize).and_return(11)
      end

      it_behaves_like 'logging behavior for decompressed content', 12.bytes
    end

    context 'when decompressed content size is below the log threshold' do
      before do
        allow(Gitlab.config.gitlab).to receive(:log_decompressed_response_bytesize).and_return(13)
      end

      it_behaves_like 'no logging for decompressed content'
    end

    context 'when log_decompressed_response_bytesize is set to zero' do
      before do
        allow(Gitlab.config.gitlab).to receive(:log_decompressed_response_bytesize).and_return(0)
      end

      it_behaves_like 'no logging for decompressed content'
    end

    context 'with chunked response' do
      let(:io) do
        chunked_response = ""
        chunked_response += "HTTP/1.1 200 OK\r\n"
        chunked_response += "Content-Encoding: gzip\r\n"
        chunked_response += "Content-Type: application/octet-stream\r\n"
        chunked_response += "Transfer-Encoding: chunked\r\n"
        chunked_response += "\r\n"
        gzipped_content = gzip_compress(body)
        gzipped_content.each_char.each_slice(1024) do |chunk|
          chunk_data = chunk.join
          chunk_size_hex = format("%X", chunk_data.bytesize)

          chunked_response += chunk_size_hex
          chunked_response += "\r\n"
          chunked_response += chunk_data
          chunked_response += "\r\n"
        end
        chunked_response << "0\r\n\r\n"

        Net::BufferedIO.new(StringIO.new(chunked_response.force_encoding('ASCII-8BIT')))
      end

      let(:body) { "A" * 2 * 1024 * 1024 }

      context 'when decompressed content size exceeds the log threshold' do
        before do
          allow(Gitlab.config.gitlab).to receive(:log_decompressed_response_bytesize).and_return(1.megabyte)
        end

        it_behaves_like 'logging behavior for decompressed content', 2.megabytes
      end

      context 'when decompressed content size is below the log threshold' do
        before do
          allow(Gitlab.config.gitlab).to receive(:log_decompressed_response_bytesize).and_return(3.megabytes)
        end

        it_behaves_like 'no logging for decompressed content'
      end
    end
  end
end
