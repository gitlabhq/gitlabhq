# frozen_string_literal: true

require 'socket'

module HttpIOHelpers
  # Minimal keep-alive HTTP server for 206 range responses, bound to an
  # OS-assigned loopback port, reached through WebMock's allow_localhost
  # pass-through. Exercises Gitlab::HttpIO against real Net::HTTP transport
  # behavior - connection reuse, transparent reconnects and error recovery -
  # which stubbed requests cannot cover, because WebMock's adapter intercepts
  # above the socket layer.
  class RangeRequestServer
    attr_reader :port, :accepts, :responses

    def initialize(body, drop_connection_after: nil)
      @body = body
      @drop_connection_after = drop_connection_after
      @failures_remaining = 0
      @truncations_remaining = 0
      @accepts = 0
      @responses = 0
      @error = nil
      @client_socket = nil
      @server = TCPServer.new('127.0.0.1', 0)
      @port = @server.addr[1]
      @thread = Thread.new { accept_loop }
    end

    # Close the next `count` connections after reading the request but before
    # responding. Net::HTTP retries an idempotent GET once on a new
    # connection, so surfacing an error to the caller requires two
    # consecutive failures.
    def fail_next_requests(count)
      @failures_remaining = count
    end

    # Send the next `count` responses with correct headers but only half the
    # promised body before closing the connection - a keep-alive socket dying
    # mid-body, after the client has consumed part of the response. As with
    # fail_next_requests, two consecutive truncations are needed to surface
    # an error through Net::HTTP's idempotent retry.
    def truncate_next_responses(count)
      @truncations_remaining = count
    end

    # Always terminates promptly: the server thread only ever blocks on
    # socket reads or accept, both of which Thread#kill interrupts. Raises
    # any error captured in the server thread so handler bugs fail the
    # example with their real backtrace instead of a client-side timeout.
    def stop
      @thread.kill
      raise "#{self.class.name} thread did not terminate" unless @thread.join(5)

      @server.close unless @server.closed?

      raise @error if @error
    end

    private

    def accept_loop
      loop do
        @client_socket = @server.accept
        @accepts += 1
        serve_connection(@client_socket)
      end
    rescue StandardError => e
      # Re-raised in #stop. The ensure below closes both sockets so the
      # client fails immediately with EOFError rather than blocking until
      # its read timeout.
      @error = e
    ensure
      @client_socket&.close
      @server.close unless @server.closed?
    end

    def serve_connection(socket)
      served = 0

      loop do
        range = read_request(socket)
        break unless range

        if @failures_remaining > 0
          @failures_remaining -= 1
          break
        end

        if @truncations_remaining > 0
          @truncations_remaining -= 1
          write_response(socket, range, truncate: true)
          break
        end

        write_response(socket, range)
        served += 1

        break if @drop_connection_after && served >= @drop_connection_after
      end
    ensure
      socket.close
    end

    # Returns the parsed Range header, or nil when the client closed the
    # connection. Always consumes the full request so that closing the socket
    # sends a clean FIN, surfacing a deterministic EOFError on the client
    # rather than a timing-dependent Errno::ECONNRESET.
    def read_request(socket)
      return unless socket.gets("\r\n") # request line

      range = nil
      loop do
        line = socket.gets("\r\n")
        break if line.nil? || line == "\r\n"

        range = line.split(':', 2).last if line.downcase.start_with?('range:')
      end

      range&.match(/bytes=(\d+)-(\d+)/)&.captures&.map(&:to_i)
    end

    def write_response(socket, range, truncate: false)
      from, to = range
      to = [to, @body.bytesize - 1].min
      chunk = @body.byteslice(from..to)

      # Count before writing: examples assert on `responses` as soon as the
      # client has read the body, which can be before this thread runs again.
      @responses += 1 unless truncate

      socket.write(
        "HTTP/1.1 206 Partial Content\r\n" \
          "Content-Type: application/octet-stream\r\n" \
          "Content-Range: bytes #{from}-#{to}/#{@body.bytesize}\r\n" \
          "Content-Length: #{chunk.bytesize}\r\n" \
          "\r\n"
      )

      chunk = chunk.byteslice(0, chunk.bytesize / 2) if truncate
      socket.write(chunk)
    end
  end

  def stub_remote_url_206(url, file_path)
    WebMock.stub_request(:get, url)
      .to_return { |request| remote_url_response(file_path, request, 206) }
  end

  def stub_remote_url_200(url, file_path)
    WebMock.stub_request(:get, url)
      .to_return { |request| remote_url_response(file_path, request, 200) }
  end

  def stub_remote_url_500(url)
    WebMock.stub_request(:get, url)
      .to_return(status: [500, "Internal Server Error"])
  end

  def remote_url_response(file_path, request, response_status)
    range = request.headers['Range'].match(/bytes=(\d+)-(\d+)/)

    body = File.read(file_path).force_encoding(Encoding::BINARY)
    size = body.bytesize

    {
      status: response_status,
      headers: remote_url_response_headers(response_status, range[1].to_i, range[2].to_i, size),
      body: body[range[1].to_i..range[2].to_i]
    }
  end

  def remote_url_response_headers(response_status, from, to, size)
    { 'Content-Type' => 'text/plain' }.tap do |headers|
      headers.merge('Content-Range' => "bytes #{from}-#{to}/#{size}") if response_status == 206
    end
  end

  def set_smaller_buffer_size_than(file_size)
    blocks = (file_size / 128)
    new_size = (blocks / 2) * 128
    stub_const("Gitlab::HttpIO::BUFFER_SIZE", new_size)
  end

  def set_larger_buffer_size_than(file_size)
    blocks = (file_size / 128)
    new_size = (blocks * 2) * 128
    stub_const("Gitlab::HttpIO::BUFFER_SIZE", new_size)
  end
end
