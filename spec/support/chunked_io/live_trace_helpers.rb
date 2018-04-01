module LiveTraceHelpers
  def fill_trace_to_chunks(data)
    stream = described_class.new(job_id, 'wb')
    stream.write(data)
    stream.close
  end

  def sample_trace_raw
    File.read(expand_fixture_path('trace/sample_trace'))
  end

  def sample_trace_size
    sample_trace_raw.length
  end

  def stub_chunk_store_get_failed
    allow_any_instance_of(Gitlab::Ci::Trace::ChunkedFile::ChunkStore::Redis).to receive(:get).and_return(nil)
    allow_any_instance_of(Gitlab::Ci::Trace::ChunkedFile::ChunkStore::Database).to receive(:get).and_return(nil)
  end

  def set_smaller_buffer_size_than(file_size)
    blocks = (file_size / 128)
    new_size = (blocks / 2) * 128
    allow_any_instance_of(described_class).to receive(:buffer_size).and_return(new_size)
  end

  def set_larger_buffer_size_than(file_size)
    blocks = (file_size / 128)
    new_size = (blocks * 2) * 128
    allow_any_instance_of(described_class).to receive(:buffer_size).and_return(new_size)
  end
end
