module ChunkedIOHelpers
  def fill_trace_to_chunks(data)
    stream = described_class.new(job_id, nil, 'a+b')
    stream.write(data)
    stream.close
  end

  def sample_trace_raw
    # ChunkStore::Database doesn't support appending, so the test data size has to be least common multiple
    if chunk_stores.first == Gitlab::Ci::Trace::ChunkedFile::ChunkStore::Database
      '01234567' * 32 # 256 bytes
    else
      File.read(expand_fixture_path('trace/sample_trace_with_byte'))
    end
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

  def set_half_buffer_size_of(file_size)
    allow_any_instance_of(described_class).to receive(:buffer_size).and_return(file_size / 2)
  end
end
