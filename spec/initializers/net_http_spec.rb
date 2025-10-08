# frozen_string_literal: true

require 'spec_helper'
require 'webrick'

RSpec.describe 'Net::Http patch', :request_store, feature_category: :integrations do
  let(:two_mega_bytes_body) { "A" * 2 * 1024 * 1024 }

  let_it_be(:server_thread) do
    Thread.new do
      server = WEBrick::HTTPServer.new(Port: 4567, Logger: WEBrick::Log.new("/dev/null"), AccessLog: [])

      server.mount_proc '/no-encoding' do |_req, res|
        res.status = 200
        res['Content-Type'] = 'text/plain'

        res.body = two_mega_bytes_body
      end

      server.mount_proc '/gzip' do |_req, res|
        res.status = 200
        res['Content-Encoding'] = 'gzip'
        res['Content-Type'] = 'text/plain'

        res.body = gzip_compress(two_mega_bytes_body)
      end

      trap("INT") { server.shutdown }

      server.start
    end
  end

  def gzip_compress(content)
    buffer = StringIO.new
    gzip = Zlib::GzipWriter.new(buffer)
    gzip.write(content)
    gzip.close
    buffer.string
  end

  before_all do
    WebMock.disable!
  end

  after(:all) do
    Thread.kill(server_thread)

    WebMock.enable!
  end

  shared_examples 'raises error' do
    it 'logs and raises Gitlab::HTTP::MaxDecompressionSizeError' do
      expect(Gitlab::AppJsonLogger).to receive(:error)
        .with(message: 'Net::HTTP - Response size too large', size: an_instance_of(Integer), caller: anything)

      expect do
        Net::HTTP.get_response(URI("http://localhost:4567/#{path}"))
      end.to raise_error Gitlab::HTTP::MaxDecompressionSizeError
    end
  end

  shared_examples 'does not raise error' do
    it 'does not raise error' do
      expect(Gitlab::AppJsonLogger).not_to receive(:error)

      body = Net::HTTP.get_response(URI("http://localhost:4567/#{path}")).body

      expect(body).to eq(two_mega_bytes_body)
    end
  end

  context 'when decompressed content size exceeds the threshold' do
    before do
      stub_application_setting(max_http_decompressed_size: 1)
    end

    include_examples 'raises error' do
      let(:path) { 'gzip' }
    end

    context 'when validation is disabled via Request Store' do
      before do
        Gitlab::SafeRequestStore[:disable_net_http_decompression] = true
      end

      include_examples 'does not raise error' do
        let(:path) { 'gzip' }
      end
    end

    context 'when response is not encoded' do
      include_examples 'does not raise error' do
        let(:path) { 'no-encoding' }
      end
    end
  end

  context 'when decompressed content size is below the threshold' do
    before do
      stub_application_setting(max_http_decompressed_size: 3)
    end

    include_examples 'does not raise error' do
      let(:path) { 'gzip' }
    end
  end

  context 'when threshold is set to zero' do
    before do
      stub_application_setting(max_http_decompressed_size: 0)
    end

    include_examples 'does not raise error' do
      let(:path) { 'gzip' }
    end
  end
end
