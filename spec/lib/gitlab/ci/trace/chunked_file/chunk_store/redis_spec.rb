require 'spec_helper'

describe Gitlab::Ci::Trace::ChunkedFile::ChunkStore::Redis, :clean_gitlab_redis_cache do
  let(:job_id) { 1 }
  let(:buffer_size) { 128.kilobytes }
  let(:chunk_index) { 0 }
  let(:buffer_key) { described_class.buffer_key(job_id, chunk_index) }
  let(:params) { { buffer_size: buffer_size } }
  let(:trace) { 'Here is the trace' }

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
        described_class.new(buffer_key, params).write!(trace)
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
        described_class.new(buffer_key, params).write!(trace)
      end

      it { is_expected.to eq(1) }

      context 'when two chunks exists' do
        let(:buffer_key_2) { described_class.buffer_key(job_id, chunk_index + 1) }
        let(:trace_2) { 'Another trace' }

        before do
          described_class.new(buffer_key_2, params).write!(trace_2)
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
        described_class.new(buffer_key, params).write!(trace)
      end

      it { is_expected.to eq(trace.length) }

      context 'when two chunks exists' do
        let(:buffer_key_2) { described_class.buffer_key(job_id, chunk_index + 1) }
        let(:trace_2) { 'Another trace' }
        let(:chunks_size) { trace.length + trace_2.length }

        before do
          described_class.new(buffer_key_2, params).write!(trace_2)
        end

        it { is_expected.to eq(chunks_size) }
      end
    end

    context 'when buffer_key does not exist' do
      it { is_expected.to eq(0) }
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
        Gitlab::Redis::Cache.with do |redis|
          redis.set(buffer_key, trace)
        end
      end

      it { is_expected.to eq(trace) }
    end

    context 'when buffer_key does not exist' do
      it { is_expected.not_to eq(trace) }
    end
  end

  describe '#size' do
    subject { described_class.new(buffer_key, params).size }

    context 'when buffer_key exists' do
      before do
        Gitlab::Redis::Cache.with do |redis|
          redis.set(buffer_key, trace)
        end
      end

      it { is_expected.to eq(trace.length) }
    end

    context 'when buffer_key does not exist' do
      it { is_expected.to eq(0) }
    end
  end

  describe '#write!' do
    subject { described_class.new(buffer_key, params).write!(trace) }

    context 'when buffer_key exists' do
      before do
        Gitlab::Redis::Cache.with do |redis|
          redis.set(buffer_key, 'Already data in the chunk')
        end
      end

      it 'overwrites' do
        is_expected.to eq(trace.length)

        Gitlab::Redis::Cache.with do |redis|
          expect(redis.get(buffer_key)).to eq(trace)
        end
      end
    end

    context 'when buffer_key does not exist' do
      it 'writes' do
        is_expected.to eq(trace.length)

        Gitlab::Redis::Cache.with do |redis|
          expect(redis.get(buffer_key)).to eq(trace)
        end
      end
    end

    context 'when data is nil' do
      let(:trace) { nil }

      it 'clears value' do
        is_expected.to eq(0)
      end
    end
  end

  describe '#truncate!' do
    subject { described_class.new(buffer_key, params).truncate!(offset) }

    let(:offset) { 5 }

    context 'when buffer_key exists' do
      before do
        Gitlab::Redis::Cache.with do |redis|
          redis.set(buffer_key, trace)
        end
      end

      it 'truncates' do
        Gitlab::Redis::Cache.with do |redis|
          expect(redis.get(buffer_key)).to eq(trace)
        end

        subject

        Gitlab::Redis::Cache.with do |redis|
          expect(redis.get(buffer_key)).to eq(trace.slice(0..offset))
        end
      end

      context 'when offset is larger than data size' do
        let(:offset) { 100 }

        it 'truncates' do
          Gitlab::Redis::Cache.with do |redis|
            expect(redis.get(buffer_key)).to eq(trace)
          end

          subject

          Gitlab::Redis::Cache.with do |redis|
            expect(redis.get(buffer_key)).to eq(trace.slice(0..offset))
          end
        end
      end
    end

    context 'when buffer_key does not exist' do
      it 'truncates' do
        Gitlab::Redis::Cache.with do |redis|
          expect(redis.get(buffer_key)).to be_nil
        end

        subject

        Gitlab::Redis::Cache.with do |redis|
          expect(redis.get(buffer_key)).to be_nil
        end
      end
    end
  end

  describe '#delete!' do
    subject { described_class.new(buffer_key, params).delete! }

    context 'when buffer_key exists' do
      before do
        Gitlab::Redis::Cache.with do |redis|
          redis.set(buffer_key, trace)
        end
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
      it 'deletes' do
        Gitlab::Redis::Cache.with do |redis|
          expect(redis.exists(buffer_key)).to be_falsy
        end

        subject

        Gitlab::Redis::Cache.with do |redis|
          expect(redis.exists(buffer_key)).to be_falsy
        end
      end
    end
  end
end
