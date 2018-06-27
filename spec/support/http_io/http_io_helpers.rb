module HttpIOHelpers
  def stub_remote_trace_206
    WebMock.stub_request(:get, remote_trace_url)
      .to_return { |request| remote_trace_response(request, 206) }
  end

  def stub_remote_trace_200
    WebMock.stub_request(:get, remote_trace_url)
      .to_return { |request| remote_trace_response(request, 200) }
  end

  def stub_remote_trace_500
    WebMock.stub_request(:get, remote_trace_url)
      .to_return(status: [500, "Internal Server Error"])
  end

  def remote_trace_url
    "http://trace.com/trace"
  end

  def remote_trace_response(request, responce_status)
    range = request.headers['Range'].match(/bytes=(\d+)-(\d+)/)

    {
      status: responce_status,
      headers: remote_trace_response_headers(responce_status, range[1].to_i, range[2].to_i),
      body: range_trace_body(range[1].to_i, range[2].to_i)
    }
  end

  def remote_trace_response_headers(responce_status, from, to)
    headers = { 'Content-Type' => 'text/plain' }

    if responce_status == 206
      headers.merge('Content-Range' => "bytes #{from}-#{to}/#{remote_trace_size}")
    end

    headers
  end

  def range_trace_body(from, to)
    remote_trace_body[from..to]
  end

  def remote_trace_body
    @remote_trace_body ||= File.read(expand_fixture_path('trace/sample_trace'))
      .force_encoding(Encoding::BINARY)
  end

  def remote_trace_size
    remote_trace_body.bytesize
  end

  def set_smaller_buffer_size_than(file_size)
    blocks = (file_size / 128)
    new_size = (blocks / 2) * 128
    stub_const("Gitlab::Ci::Trace::HttpIO::BUFFER_SIZE", new_size)
  end

  def set_larger_buffer_size_than(file_size)
    blocks = (file_size / 128)
    new_size = (blocks * 2) * 128
    stub_const("Gitlab::Ci::Trace::HttpIO::BUFFER_SIZE", new_size)
  end
end
