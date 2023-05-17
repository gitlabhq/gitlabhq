# frozen_string_literal: true

module HttpIOHelpers
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
