require 'spec_helper'

describe Gitlab::Ci::Trace::ChunkedFile::ChunkedIO, :clean_gitlab_redis_cache do
  include ChunkedIOHelpers

  let(:chunked_io) { described_class.new(job_id, size, mode) }
  let(:job_id) { 1 }
  let(:size) { sample_trace_size }
  let(:mode) { 'rb' }
  let(:buffer_size) { 128.kilobytes }
  let(:chunk_store) { Gitlab::Ci::Trace::ChunkedFile::ChunkStore::Redis }

  before do
    allow_any_instance_of(described_class).to receive(:chunk_store).and_return(chunk_store)
    stub_const("Gitlab::Ci::Trace::ChunkedFile::ChunkedIO::BUFFER_SIZE", buffer_size)
  end

  describe '#new' do
    context 'when mode is read' do
      let(:mode) { 'rb' }

      it 'raises no exception' do
        described_class.new(job_id, size, mode)

        expect { described_class.new(job_id, size, mode) }.not_to raise_error
      end
    end

    context 'when mode is write' do
      let(:mode) { 'a+b' }

      it 'raises an exception' do
        described_class.new(job_id, size, mode)

        expect { described_class.new(job_id, size, mode) }.to raise_error('Already opened by another process')
      end

      context 'when closed after open' do
        it 'does not raise an exception' do
          described_class.new(job_id, size, mode).close

          expect { described_class.new(job_id, size, mode) }.not_to raise_error
        end
      end
    end
  end

  describe '#seek' do
    subject { chunked_io.seek(pos, where) }

    context 'when moves pos to end of the file' do
      let(:pos) { 0 }
      let(:where) { IO::SEEK_END }

      it { is_expected.to eq(size) }
    end

    context 'when moves pos to middle of the file' do
      let(:pos) { size / 2 }
      let(:where) { IO::SEEK_SET }

      it { is_expected.to eq(size / 2) }
    end

    context 'when moves pos around' do
      it 'matches the result' do
        expect(chunked_io.seek(0)).to eq(0)
        expect(chunked_io.seek(100, IO::SEEK_CUR)).to eq(100)
        expect { chunked_io.seek(size + 1, IO::SEEK_CUR) }.to raise_error('new position is outside of file')
      end
    end
  end

  describe '#eof?' do
    subject { chunked_io.eof? }

    context 'when current pos is at end of the file' do
      before do
        chunked_io.seek(size, IO::SEEK_SET)
      end

      it { is_expected.to be_truthy }
    end

    context 'when current pos is not at end of the file' do
      before do
        chunked_io.seek(0, IO::SEEK_SET)
      end

      it { is_expected.to be_falsey }
    end
  end

  describe '#each_line' do
    let(:buffer_size) { 128.kilobytes }
    let(:string_io) { StringIO.new(sample_trace_raw) }

    context 'when BUFFER_SIZE is smaller than file size' do
      before do
        set_smaller_buffer_size_than(size)
        fill_trace_to_chunks(sample_trace_raw)
      end

      it 'yields lines' do
        expect { |b| described_class.new(job_id, size, 'rb').each_line(&b) }
          .to yield_successive_args(*string_io.each_line.to_a)
      end
    end

    context 'when BUFFER_SIZE is larger than file size' do
      let(:buffer_size) { size + 1000 }

      before do
        set_larger_buffer_size_than(size)
        fill_trace_to_chunks(sample_trace_raw)
      end

      it 'calls get_chunk only once' do
        expect(chunk_store).to receive(:open).once.and_call_original

        described_class.new(job_id, size, 'rb').each_line { |line| }
      end
    end
  end

  describe '#read' do
    subject { described_class.new(job_id, size, 'rb').read(length) }

    context 'when read whole size' do
      let(:length) { nil }

      context 'when BUFFER_SIZE is smaller than file size', :clean_gitlab_redis_cache do
        before do
          set_smaller_buffer_size_than(size)
          fill_trace_to_chunks(sample_trace_raw)
        end

        it 'reads a trace' do
          is_expected.to eq(sample_trace_raw)
        end
      end

      context 'when BUFFER_SIZE is larger than file size', :clean_gitlab_redis_cache do
        before do
          set_larger_buffer_size_than(size)
          fill_trace_to_chunks(sample_trace_raw)
        end

        it 'reads a trace' do
          is_expected.to eq(sample_trace_raw)
        end
      end
    end

    context 'when read only first 100 bytes' do
      let(:length) { 100 }

      context 'when BUFFER_SIZE is smaller than file size', :clean_gitlab_redis_cache do
        before do
          set_smaller_buffer_size_than(size)
          fill_trace_to_chunks(sample_trace_raw)
        end

        it 'reads a trace' do
          is_expected.to eq(sample_trace_raw[0, length])
        end
      end

      context 'when BUFFER_SIZE is larger than file size', :clean_gitlab_redis_cache do
        before do
          set_larger_buffer_size_than(size)
          fill_trace_to_chunks(sample_trace_raw)
        end

        it 'reads a trace' do
          is_expected.to eq(sample_trace_raw[0, length])
        end
      end
    end

    context 'when tries to read oversize' do
      let(:length) { size + 1000 }

      context 'when BUFFER_SIZE is smaller than file size' do
        before do
          set_smaller_buffer_size_than(size)
          fill_trace_to_chunks(sample_trace_raw)
        end

        it 'reads a trace' do
          is_expected.to eq(sample_trace_raw)
        end
      end

      context 'when BUFFER_SIZE is larger than file size' do
        before do
          set_larger_buffer_size_than(size)
          fill_trace_to_chunks(sample_trace_raw)
        end

        it 'reads a trace' do
          is_expected.to eq(sample_trace_raw)
        end
      end
    end

    context 'when tries to read 0 bytes' do
      let(:length) { 0 }

      context 'when BUFFER_SIZE is smaller than file size' do
        before do
          set_smaller_buffer_size_than(size)
          fill_trace_to_chunks(sample_trace_raw)
        end

        it 'reads a trace' do
          is_expected.to be_empty
        end
      end

      context 'when BUFFER_SIZE is larger than file size' do
        before do
          set_larger_buffer_size_than(size)
          fill_trace_to_chunks(sample_trace_raw)
        end

        it 'reads a trace' do
          is_expected.to be_empty
        end
      end
    end

    context 'when chunk store failed to get chunk' do
      let(:length) { nil }

      before do
        fill_trace_to_chunks(sample_trace_raw)

        stub_chunk_store_redis_get_failed
      end

      it 'reads a trace' do
        expect { subject }.to raise_error(Gitlab::Ci::Trace::ChunkedFile::ChunkedIO::FailedToGetChunkError)
      end
    end
  end

  describe '#readline' do
    subject { chunked_io.readline }

    let(:string_io) { StringIO.new(sample_trace_raw) }

    shared_examples 'all line matching' do
      it 'reads a line' do
        (0...sample_trace_raw.lines.count).each do
          expect(chunked_io.readline).to eq(string_io.readline)
        end
      end
    end

    context 'when chunk store failed to get chunk' do
      let(:length) { nil }

      before do
        fill_trace_to_chunks(sample_trace_raw)
        stub_chunk_store_redis_get_failed
      end

      it 'reads a trace' do
        expect { subject }.to raise_error(Gitlab::Ci::Trace::ChunkedFile::ChunkedIO::FailedToGetChunkError)
      end
    end

    context 'when BUFFER_SIZE is smaller than file size' do
      before do
        set_smaller_buffer_size_than(size)
        fill_trace_to_chunks(sample_trace_raw)
      end

      it_behaves_like 'all line matching'
    end

    context 'when BUFFER_SIZE is larger than file size' do
      before do
        set_larger_buffer_size_than(size)
        fill_trace_to_chunks(sample_trace_raw)
      end

      it_behaves_like 'all line matching'
    end

    context 'when pos is at middle of the file' do
      before do
        set_smaller_buffer_size_than(size)
        fill_trace_to_chunks(sample_trace_raw)

        chunked_io.seek(size / 2)
        string_io.seek(size / 2)
      end

      it 'reads from pos' do
        expect(chunked_io.readline).to eq(string_io.readline)
      end
    end
  end

  describe '#write' do
    subject { chunked_io.write(data) }

    let(:data) { sample_trace_raw }

    context 'when write mdoe' do
      let(:mode) { 'wb' }

      context 'when BUFFER_SIZE is smaller than file size', :clean_gitlab_redis_cache do
        before do
          set_smaller_buffer_size_than(size)
        end

        it 'writes a trace' do
          is_expected.to eq(data.length)

          Gitlab::Ci::Trace::ChunkedFile::ChunkedIO.open(job_id, size, 'rb') do |stream|
            expect(stream.read).to eq(data)
            expect(chunk_store.chunks_count(job_id)).to eq(stream.send(:chunks_count))
            expect(chunk_store.chunks_size(job_id)).to eq(data.length)
          end
        end
      end

      context 'when BUFFER_SIZE is larger than file size', :clean_gitlab_redis_cache do
        before do
          set_larger_buffer_size_than(size)
        end

        it 'writes a trace' do
          is_expected.to eq(data.length)

          Gitlab::Ci::Trace::ChunkedFile::ChunkedIO.open(job_id, size, 'rb') do |stream|
            expect(stream.read).to eq(data)
            expect(chunk_store.chunks_count(job_id)).to eq(stream.send(:chunks_count))
            expect(chunk_store.chunks_size(job_id)).to eq(data.length)
          end
        end
      end

      context 'when data is nil' do
        let(:data) { nil }

        it 'writes a trace' do
          expect { subject } .to raise_error('Could not write empty data')
        end
      end
    end

    context 'when append mdoe' do
      let(:original_data) { 'original data' }
      let(:total_size) { original_data.length + data.length }

      context 'when BUFFER_SIZE is smaller than file size', :clean_gitlab_redis_cache do
        before do
          set_smaller_buffer_size_than(size)
          fill_trace_to_chunks(original_data)
        end

        it 'appends a trace' do
          described_class.open(job_id, original_data.length, 'a+b') do |stream|
            expect(stream.write(data)).to eq(data.length)
          end

          described_class.open(job_id, total_size, 'rb') do |stream|
            expect(stream.read).to eq(original_data + data)
            expect(chunk_store.chunks_count(job_id)).to eq(stream.send(:chunks_count))
            expect(chunk_store.chunks_size(job_id)).to eq(total_size)
          end
        end
      end

      context 'when BUFFER_SIZE is larger than file size', :clean_gitlab_redis_cache do
        before do
          set_larger_buffer_size_than(size)
          fill_trace_to_chunks(original_data)
        end

        it 'appends a trace' do
          described_class.open(job_id, original_data.length, 'a+b') do |stream|
            expect(stream.write(data)).to eq(data.length)
          end

          described_class.open(job_id, total_size, 'rb') do |stream|
            expect(stream.read).to eq(original_data + data)
            expect(chunk_store.chunks_count(job_id)).to eq(stream.send(:chunks_count))
            expect(chunk_store.chunks_size(job_id)).to eq(total_size)
          end
        end
      end
    end
  end

  describe '#truncate' do
    context 'when data exists' do
      context 'when BUFFER_SIZE is smaller than file size', :clean_gitlab_redis_cache do
        before do
          set_smaller_buffer_size_than(size)
          fill_trace_to_chunks(sample_trace_raw)
        end

        it 'truncates a trace' do
          described_class.open(job_id, size, 'rb') do |stream|
            expect(stream.read).to eq(sample_trace_raw)
          end

          described_class.open(job_id, size, 'wb') do |stream|
            stream.truncate(0)
          end

          described_class.open(job_id, 0, 'rb') do |stream|
            expect(stream.read).to be_empty
          end

          expect(chunk_store.chunks_count(job_id)).to eq(0)
          expect(chunk_store.chunks_size(job_id)).to eq(0)
        end

        context 'when offset is negative', :clean_gitlab_redis_cache do
          it 'raises an error' do
            described_class.open(job_id, size, 'wb') do |stream|
              expect { stream.truncate(-1) }.to raise_error('Offset is out of bound')
            end
          end
        end

        context 'when offset is larger than file size', :clean_gitlab_redis_cache do
          it 'raises an error' do
            described_class.open(job_id, size, 'wb') do |stream|
              expect { stream.truncate(size + 1) }.to raise_error('Offset is out of bound')
            end
          end
        end
      end

      context 'when BUFFER_SIZE is larger than file size', :clean_gitlab_redis_cache do
        before do
          set_larger_buffer_size_than(size)
          fill_trace_to_chunks(sample_trace_raw)
        end

        it 'truncates a trace' do
          described_class.open(job_id, size, 'rb') do |stream|
            expect(stream.read).to eq(sample_trace_raw)
          end

          described_class.open(job_id, size, 'wb') do |stream|
            stream.truncate(0)
          end

          described_class.open(job_id, 0, 'rb') do |stream|
            expect(stream.read).to be_empty
          end

          expect(chunk_store.chunks_count(job_id)).to eq(0)
          expect(chunk_store.chunks_size(job_id)).to eq(0)
        end
      end
    end

    context 'when data does not exist' do
      before do
        set_smaller_buffer_size_than(size)
      end

      it 'truncates a trace' do
        described_class.open(job_id, size, 'wb') do |stream|
          stream.truncate(0)
          expect(stream.send(:tell)).to eq(0)
          expect(stream.send(:size)).to eq(0)
        end
      end
    end
  end
end
