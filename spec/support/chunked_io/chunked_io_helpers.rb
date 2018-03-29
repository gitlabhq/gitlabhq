module ChunkedIOHelpers
  def fill_trace_to_chunks(data)
    stream = Gitlab::Ci::Trace::ChunkedFile::ChunkedIO.new(job_id, data.length, 'wb')
    stream.write(data)
    stream.close
  end

  def sample_trace_raw
    @sample_trace_raw ||= File.read(expand_fixture_path('trace/sample_trace'))
  end

  def sample_trace_size
    sample_trace_raw.length
  end

  def stub_chunk_store_redis_get_failed
    allow_any_instance_of(Gitlab::Ci::Trace::ChunkedFile::ChunkStore::Redis)
      .to receive(:get).and_return(nil)
  end

  def set_smaller_buffer_size_than(file_size)
    blocks = (file_size / 128)
    new_size = (blocks / 2) * 128
    stub_const("Gitlab::Ci::Trace::ChunkedFile::ChunkedIO::BUFFER_SIZE", new_size)
  end

  def set_larger_buffer_size_than(file_size)
    blocks = (file_size / 128)
    new_size = (blocks * 2) * 128
    stub_const("Gitlab::Ci::Trace::ChunkedFile::ChunkedIO::BUFFER_SIZE", new_size)
  end
end
