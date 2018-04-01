module ChunkedIOHelpers
  def fill_trace_to_chunks(data)
    stream = described_class.new(job_id, data.length, 'wb')
    stream.write(data)
    stream.close
  end

  def sample_trace_raw
    if chunk_store == Gitlab::Ci::Trace::ChunkedFile::ChunkStore::Redis
      File.read(expand_fixture_path('trace/sample_trace'))
    else
      '01234567' * 32
    end
  end

  def sample_trace_size
    sample_trace_raw.length
  end

  def sample_trace_raw_for_live_trace
    File.read(expand_fixture_path('trace/sample_trace'))
  end

  def sample_trace_size_for_live_trace
    sample_trace_raw_for_live_trace.length
  end

  def fill_trace_to_chunks_for_live_trace(data)
    stream = described_class.new(job_id, 'wb')
    stream.write(data)
    stream.close
  end

  def stub_chunk_store_get_failed
    allow_any_instance_of(chunk_store).to receive(:get).and_return(nil)
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
