# frozen_string_literal: true

module ChunkedIOHelpers
  def sample_trace_raw
    @sample_trace_raw ||= File.read(expand_fixture_path('trace/sample_trace'))
      .force_encoding(Encoding::BINARY)
  end

  def stub_buffer_size(size)
    stub_const('Ci::BuildTraceChunk::CHUNK_SIZE', size)
    stub_const('Gitlab::Ci::Trace::ChunkedIO::CHUNK_SIZE', size)
  end
end
