require 'spec_helper'

describe Gitlab::Ci::Trace::ChunkedFile::ChunkStore::Redis, :clean_gitlab_redis_cache do
  let(:job) { create(:ci_build) }
  let(:job_id) { job.id }
  let(:chunk_index) { 0 }
  let(:buffer_size) { 128.kilobytes }
  let(:buffer_key) { described_class.buffer_key(job_id, chunk_index) }
  let(:params) { { buffer_size: buffer_size } }
  let(:data) { 'Here is the trace' }

  describe '.open' do
    subject { described_class.open(job_id, chunk_index, params) }

    it 'opens' do
      expect { |b| described_class.open(job_id, chunk_index, params, &b) }
        .to yield_successive_args(described_class)
    end

    context 'when job_id is nil' do
      let(:job_id) { nil }

      it { expect { subject }.to raise_error(ArgumentError) }
    end

    context 'when chunk_index is nil' do
      let(:chunk_index) { nil }

      it { expect { subject }.to raise_error(ArgumentError) }
    end
  end

  describe '.exist?' do
    subject { described_class.exist?(job_id, chunk_index) }

    context 'when buffer_key exists' do
      before do
        described_class.new(buffer_key, params).write!(data)
      end

      it { is_expected.to be_truthy }
    end

    context 'when buffer_key does not exist' do
      it { is_expected.to be_falsy }
    end
  end

  describe '.chunks_count' do
    subject { described_class.chunks_count(job_id) }

    context 'when buffer_key exists' do
      before do
        described_class.new(buffer_key, params).write!(data)
      end

      it { is_expected.to eq(1) }

      context 'when two chunks exists' do
        let(:buffer_key_2) { described_class.buffer_key(job_id, chunk_index + 1) }
        let(:data_2) { 'Another data' }

        before do
          described_class.new(buffer_key_2, params).write!(data_2)
        end

        it { is_expected.to eq(2) }
      end
    end

    context 'when buffer_key does not exist' do
      it { is_expected.to eq(0) }
    end
  end

  describe '.chunks_size' do
    subject { described_class.chunks_size(job_id) }

    context 'when buffer_key exists' do
      before do
        described_class.new(buffer_key, params).write!(data)
      end

      it { is_expected.to eq(data.length) }

      context 'when two chunks exists' do
        let(:buffer_key_2) { described_class.buffer_key(job_id, chunk_index + 1) }
        let(:data_2) { 'Another data' }
        let(:chunks_size) { data.length + data_2.length }

        before do
          described_class.new(buffer_key_2, params).write!(data_2)
        end

        it { is_expected.to eq(chunks_size) }
      end
    end

    context 'when buffer_key does not exist' do
      it { is_expected.to eq(0) }
    end
  end

  describe '.delete_all' do
    subject { described_class.delete_all(job_id) }

    context 'when buffer_key exists' do
      before do
        described_class.new(buffer_key, params).write!(data)
      end

      it 'deletes all' do
        expect { subject }.to change { described_class.chunks_count(job_id) }.by(-1)
      end

      context 'when two chunks exists' do
        let(:buffer_key_2) { described_class.buffer_key(job_id, chunk_index + 1) }
        let(:data_2) { 'Another data' }

        before do
          described_class.new(buffer_key_2, params).write!(data_2)
        end

        it 'deletes all' do
          expect { subject }.to change { described_class.chunks_count(job_id) }.by(-2)
        end
      end
    end

    context 'when buffer_key does not exist' do
      it 'deletes all' do
        expect { subject }.not_to change { described_class.chunks_count(job_id) }
      end
    end
  end

  describe '.buffer_key' do
    subject { described_class.buffer_key(job_id, chunk_index) }

    it { is_expected.to eq("live_trace_buffer:#{job_id}:#{chunk_index}") }
  end

  describe '#get' do
    subject { described_class.new(buffer_key, params).get }

    context 'when buffer_key exists' do
      before do
        described_class.new(buffer_key, params).write!(data)
      end

      it { is_expected.to eq(data) }
    end

    context 'when buffer_key does not exist' do
      it { is_expected.to be_nil }
    end
  end

  describe '#size' do
    subject { described_class.new(buffer_key, params).size }

    context 'when buffer_key exists' do
      before do
        described_class.new(buffer_key, params).write!(data)
      end

      it { is_expected.to eq(data.length) }
    end

    context 'when buffer_key does not exist' do
      it { is_expected.to eq(0) }
    end
  end

  describe '#write!' do
    subject { described_class.new(buffer_key, params).write!(data) }

    context 'when buffer_key exists' do
      before do
        described_class.new(buffer_key, params).write!('Already data in the data')
      end

      it 'overwrites' do
        is_expected.to eq(data.length)

        Gitlab::Redis::Cache.with do |redis|
          expect(redis.get(buffer_key)).to eq(data)
        end
      end
    end

    context 'when buffer_key does not exist' do
      it 'writes' do
        is_expected.to eq(data.length)

        Gitlab::Redis::Cache.with do |redis|
          expect(redis.get(buffer_key)).to eq(data)
        end
      end
    end

    context 'when data is nil' do
      let(:data) { nil }

      it 'clears value' do
        expect { described_class.new(buffer_key, params).write!(data) }
          .to raise_error('Could not write empty data')
      end
    end
  end

  describe '#append!' do
    subject { described_class.new(buffer_key, params).append!(data) }

    context 'when buffer_key exists' do
      let(:written_chunk) { 'Already data in the data' }

      before do
        described_class.new(buffer_key, params).write!(written_chunk)
      end

      it 'appends' do
        is_expected.to eq(data.length)

        Gitlab::Redis::Cache.with do |redis|
          expect(redis.get(buffer_key)).to eq(written_chunk + data)
        end
      end
    end

    context 'when buffer_key does not exist' do
      it 'raises an error' do
        expect { subject }.to raise_error(described_class::BufferKeyNotFoundError)
      end
    end

    context 'when data is nil' do
      let(:data) { nil }

      it 'raises an error' do
        expect { subject }.to raise_error('Could not write empty data')
      end
    end
  end

  describe '#delete!' do
    subject { described_class.new(buffer_key, params).delete! }

    context 'when buffer_key exists' do
      before do
        described_class.new(buffer_key, params).write!(data)
      end

      it 'deletes' do
        Gitlab::Redis::Cache.with do |redis|
          expect(redis.exists(buffer_key)).to be_truthy
        end

        subject

        Gitlab::Redis::Cache.with do |redis|
          expect(redis.exists(buffer_key)).to be_falsy
        end
      end
    end

    context 'when buffer_key does not exist' do
      it 'raises an error' do
        expect { subject }.to raise_error(described_class::BufferKeyNotFoundError)
      end
    end
  end
end
