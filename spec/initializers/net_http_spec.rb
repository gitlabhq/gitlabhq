# frozen_string_literal: true

require 'spec_helper'
require 'webrick'

RSpec.describe 'Net::Http patch', :request_store, feature_category: :integrations do
  let(:two_mega_bytes_body) { "A" * 2 * 1024 * 1024 }

  let_it_be(:server_port) { 4567 }

  let_it_be(:server_thread) do
    Thread.new do
      server = WEBrick::HTTPServer.new(Port: server_port, Logger: WEBrick::Log.new("/dev/null"), AccessLog: [])

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

      server.mount_proc '/continue' do |_req, res|
        res.status = 100
        res['Content-Type'] = 'text/plain'
        res.body = 'Continue'
      end

      server.mount_proc '/switching-protocols' do |_req, res|
        res.status = 101
        res['Content-Type'] = 'text/plain'
        res.body = 'Switching Protocols'
      end

      server.mount_proc '/processing' do |_req, res|
        res.status = 102
        res['Content-Type'] = 'text/plain'
        res.body = 'Processing'
      end

      server.mount_proc '/early_hints' do |_req, res|
        res.status = 103
        res['Content-Type'] = 'text/plain'
        res.body = 'Early Hints'
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

  def wait_for_server(port, timeout: 5)
    Timeout.timeout(timeout) do
      loop do
        TCPSocket.new('localhost', port).close
        break
      rescue Errno::ECONNREFUSED, Errno::EADDRNOTAVAIL
        sleep 0.5
      end
    end
  rescue Timeout::Error
    raise "Server on port #{port} failed to start within #{timeout} seconds"
  end

  before_all do
    WebMock.disable!
    wait_for_server(server_port)
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
        Net::HTTP.get_response(URI("http://localhost:#{server_port}/#{path}"))
      end.to raise_error Gitlab::HTTP::MaxDecompressionSizeError
    end
  end

  shared_examples 'does not raise error' do
    it 'does not raise error' do
      expect(Gitlab::AppJsonLogger).not_to receive(:error)

      body = Net::HTTP.get_response(URI("http://localhost:#{server_port}/#{path}")).body

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

  describe 'HTTPInformation monkey patch with HTTP requests' do
    it 'raises InvalidResponseError when server returns 100 Continue' do
      expect do
        Net::HTTP.get_response(URI("http://localhost:4567/continue"))
      end.to raise_error(Gitlab::HTTP::InvalidResponseError, 'Invalid server response: 1xx responses not supported')
    end

    it 'raises InvalidResponseError when server returns 101 Switching Protocols' do
      expect do
        Net::HTTP.get_response(URI("http://localhost:4567/switching-protocols"))
      end.to raise_error(Gitlab::HTTP::InvalidResponseError, 'Invalid server response: 1xx responses not supported')
    end

    it 'raises InvalidResponseError when server returns 102 Processing' do
      expect do
        Net::HTTP.get_response(URI("http://localhost:4567/processing"))
      end.to raise_error(Gitlab::HTTP::InvalidResponseError, 'Invalid server response: 1xx responses not supported')
    end

    it 'raises InvalidResponseError when server returns 103 Early Hints' do
      expect do
        Net::HTTP.get_response(URI("http://localhost:4567/early_hints"))
      end.to raise_error(Gitlab::HTTP::InvalidResponseError, 'Invalid server response: 1xx responses not supported')
    end

    # Test with different HTTP methods
    it 'raises InvalidResponseError on POST request returning 1xx' do
      expect do
        uri = URI("http://localhost:4567/continue")
        Net::HTTP.post(uri, 'test data')
      end.to raise_error(Gitlab::HTTP::InvalidResponseError, 'Invalid server response: 1xx responses not supported')
    end

    it 'raises InvalidResponseError with custom HTTP instance' do
      expect do
        http = Net::HTTP.new('localhost', 4567)
        http.start do |connection|
          connection.get('/continue')
        end
      end.to raise_error(Gitlab::HTTP::InvalidResponseError, 'Invalid server response: 1xx responses not supported')
    end
  end
end
