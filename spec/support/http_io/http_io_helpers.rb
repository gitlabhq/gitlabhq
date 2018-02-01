module HttpIOHelpers
  def stub_remote_trace_ok
    WebMock.stub_request(:get, remote_trace_url)
      .to_return { |request| remote_trace_response(request) }
  end

  def stub_remote_trace_ng
    WebMock.stub_request(:get, remote_trace_url)
      .to_return(status: [500, "Internal Server Error"])
  end

  def remote_trace_url
    "http://trace.com/trace"
  end

  def remote_trace_response(request)
    range = request.headers['Range'].match(/bytes=(\d+)-(\d+)/)

    {
      status: 200,
      headers: { 'Content-Type' => 'text/plain' },
      body: range_trace_body(range[1].to_i, range[2].to_i)
    }
  end

  def range_trace_body(from ,to)
    remote_trace_body[from..to]
  end

  def remote_trace_body
    @remote_trace_body ||= File.read(expand_fixture_path('trace/sample_trace'))
  end

  def remote_trace_size
    remote_trace_body.length
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
