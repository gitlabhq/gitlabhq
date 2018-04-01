require 'spec_helper'

describe Gitlab::Ci::Trace::ChunkedFile::LiveTrace, :clean_gitlab_redis_cache do
  include LiveTraceHelpers

  let(:chunked_io) { described_class.new(job_id, mode) }
  let(:job) { create(:ci_build) }
  let(:job_id) { job.id }
  let(:size) { sample_trace_size }
  let(:mode) { 'rb' }

  describe '#write' do
    subject { chunked_io.write(data) }

    let(:data) { sample_trace_raw }

    context 'when write mode' do
      let(:mode) { 'wb' }

      context 'when buffer size is smaller than file size' do
        before do
          set_smaller_buffer_size_than(size)
        end

        it 'writes a trace' do
          is_expected.to eq(data.length)

          described_class.open(job_id, 'rb') do |stream|
            expect(stream.read).to eq(data)
            expect(total_chunks_count).to eq(stream.send(:chunks_count))
            expect(total_chunks_size).to eq(data.length)
          end
        end
      end

      context 'when buffer size is larger than file size' do
        before do
          set_larger_buffer_size_than(size)
        end

        it 'writes a trace' do
          is_expected.to eq(data.length)

          described_class.open(job_id, 'rb') do |stream|
            expect(stream.read).to eq(data)
            expect(total_chunks_count).to eq(stream.send(:chunks_count))
            expect(total_chunks_size).to eq(data.length)
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

    context 'when append mode' do
      let(:original_data) { 'original data' }
      let(:total_size) { original_data.length + data.length }

      context 'when buffer size is smaller than file size' do
        before do
          set_smaller_buffer_size_than(size)
          fill_trace_to_chunks(original_data)
        end

        it 'appends a trace' do
          described_class.open(job_id, 'a+b') do |stream|
            expect(stream.write(data)).to eq(data.length)
          end

          described_class.open(job_id, 'rb') do |stream|
            expect(stream.read).to eq(original_data + data)
            expect(total_chunks_count).to eq(stream.send(:chunks_count))
            expect(total_chunks_size).to eq(total_size)
          end
        end
      end

      context 'when buffer size is larger than file size' do
        before do
          set_larger_buffer_size_than(size)
          fill_trace_to_chunks(original_data)
        end

        it 'appends a trace' do
          described_class.open(job_id, 'a+b') do |stream|
            expect(stream.write(data)).to eq(data.length)
          end

          described_class.open(job_id, 'rb') do |stream|
            expect(stream.read).to eq(original_data + data)
            expect(total_chunks_count).to eq(stream.send(:chunks_count))
            expect(total_chunks_size).to eq(total_size)
          end
        end
      end
    end
  end

  describe '#truncate' do
    context 'when data exists' do
      context 'when buffer size is smaller than file size' do
        before do
          puts "#{self.class.name} - #{__callee__}: ===== 1"
          set_smaller_buffer_size_than(size)
          fill_trace_to_chunks(sample_trace_raw)
        end

        it 'truncates a trace' do
          puts "#{self.class.name} - #{__callee__}: ===== 2"
          described_class.open(job_id, 'rb') do |stream|
            expect(stream.read).to eq(sample_trace_raw)
          end

          puts "#{self.class.name} - #{__callee__}: ===== 3"
          described_class.open(job_id, 'wb') do |stream|
            stream.truncate(0)
          end

          puts "#{self.class.name} - #{__callee__}: ===== 4"
          expect(total_chunks_count).to eq(0)
          expect(total_chunks_size).to eq(0)
          
          puts "#{self.class.name} - #{__callee__}: ===== 5"
          described_class.open(job_id, 'rb') do |stream|
            expect(stream.read).to be_empty
          end
        end

        context 'when offset is negative' do
          it 'raises an error' do
            described_class.open(job_id, 'wb') do |stream|
              expect { stream.truncate(-1) }.to raise_error('Offset is out of bound')
            end
          end
        end

        context 'when offset is larger than file size' do
          it 'raises an error' do
            described_class.open(job_id, 'wb') do |stream|
              expect { stream.truncate(size + 1) }.to raise_error('Offset is out of bound')
            end
          end
        end
      end

      context 'when buffer size is larger than file size' do
        before do
          set_larger_buffer_size_than(size)
          fill_trace_to_chunks(sample_trace_raw)
        end

        it 'truncates a trace' do
          described_class.open(job_id, 'rb') do |stream|
            expect(stream.read).to eq(sample_trace_raw)
          end

          described_class.open(job_id, 'wb') do |stream|
            stream.truncate(0)
          end

          described_class.open(job_id, 'rb') do |stream|
            expect(stream.read).to be_empty
          end

          expect(total_chunks_count).to eq(0)
          expect(total_chunks_size).to eq(0)
        end
      end
    end

    context 'when data does not exist' do
      before do
        set_smaller_buffer_size_than(size)
      end

      it 'truncates a trace' do
        described_class.open(job_id, 'wb') do |stream|
          stream.truncate(0)
          expect(stream.send(:tell)).to eq(0)
          expect(stream.send(:size)).to eq(0)
        end
      end
    end
  end

  def total_chunks_count
    Gitlab::Ci::Trace::ChunkedFile::ChunkStore::Redis.chunks_count(job_id) +
      Gitlab::Ci::Trace::ChunkedFile::ChunkStore::Database.chunks_count(job_id)
  end

  def total_chunks_size
    Gitlab::Ci::Trace::ChunkedFile::ChunkStore::Redis.chunks_size(job_id) +
      Gitlab::Ci::Trace::ChunkedFile::ChunkStore::Database.chunks_size(job_id)
  end
end
