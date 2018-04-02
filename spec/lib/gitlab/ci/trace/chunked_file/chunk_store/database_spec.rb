require 'spec_helper'

describe Gitlab::Ci::Trace::ChunkedFile::ChunkStore::Database do
  let(:job) { create(:ci_build) }
  let(:job_id) { job.id }
  let(:chunk_index) { 0 }
  let(:buffer_size) { 256 }
  let(:job_trace_chunk) { ::Ci::JobTraceChunk.new(job_id: job_id, chunk_index: chunk_index) }
  let(:params) { { buffer_size: buffer_size } }
  let(:data) { 'A' * buffer_size }

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

    context 'when job_trace_chunk exists' do
      before do
        described_class.new(job_trace_chunk, params).write!(data)
      end

      it { is_expected.to be_truthy }
    end

    context 'when job_trace_chunk does not exist' do
      it { is_expected.to be_falsy }
    end
  end

  describe '.chunks_count' do
    subject { described_class.chunks_count(job_id) }

    context 'when job_trace_chunk exists' do
      before do
        described_class.new(job_trace_chunk, params).write!(data)
      end

      it { is_expected.to eq(1) }

      context 'when two chunks exists' do
        let(:job_trace_chunk_2) { ::Ci::JobTraceChunk.new(job_id: job_id, chunk_index: chunk_index + 1) }
        let(:data_2) { 'B' * buffer_size }

        before do
          described_class.new(job_trace_chunk_2, params).write!(data_2)
        end

        it { is_expected.to eq(2) }
      end
    end

    context 'when job_trace_chunk does not exist' do
      it { is_expected.to eq(0) }
    end
  end

  describe '.chunks_size' do
    subject { described_class.chunks_size(job_id) }

    context 'when job_trace_chunk exists' do
      before do
        described_class.new(job_trace_chunk, params).write!(data)
      end

      it { is_expected.to eq(data.length) }

      context 'when two chunks exists' do
        let(:job_trace_chunk_2) { ::Ci::JobTraceChunk.new(job_id: job_id, chunk_index: chunk_index + 1) }
        let(:data_2) { 'B' * buffer_size }
        let(:chunks_size) { data.length + data_2.length }

        before do
          described_class.new(job_trace_chunk_2, params).write!(data_2)
        end

        it { is_expected.to eq(chunks_size) }
      end
    end

    context 'when job_trace_chunk does not exist' do
      it { is_expected.to eq(0) }
    end
  end

  describe '.delete_all' do
    subject { described_class.delete_all(job_id) }

    context 'when job_trace_chunk exists' do
      before do
        described_class.new(job_trace_chunk, params).write!(data)
      end

      it 'deletes all' do
        expect { subject }.to change { described_class.chunks_count(job_id) }.by(-1)
      end

      context 'when two chunks exists' do
        let(:job_trace_chunk_2) { ::Ci::JobTraceChunk.new(job_id: job_id, chunk_index: chunk_index + 1) }
        let(:data_2) { 'B' * buffer_size }

        before do
          described_class.new(job_trace_chunk_2, params).write!(data_2)
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

  describe '#get' do
    subject { described_class.new(job_trace_chunk, params).get }

    context 'when job_trace_chunk exists' do
      before do
        described_class.new(job_trace_chunk, params).write!(data)
      end

      it { is_expected.to eq(data) }
    end

    context 'when job_trace_chunk does not exist' do
      it { is_expected.to be_nil }
    end
  end

  describe '#size' do
    subject { described_class.new(job_trace_chunk, params).size }

    context 'when job_trace_chunk exists' do
      before do
        described_class.new(job_trace_chunk, params).write!(data)
      end

      it { is_expected.to eq(data.length) }
    end

    context 'when job_trace_chunk does not exist' do
      it { is_expected.to eq(0) }
    end
  end

  describe '#write!' do
    subject { described_class.new(job_trace_chunk, params).write!(data) }

    context 'when job_trace_chunk exists' do
      before do
        described_class.new(job_trace_chunk, params).write!(data)
      end

      it { expect { subject }.to raise_error('UPDATE (Overwriting data) is not supported') }
    end

    context 'when job_trace_chunk does not exist' do
      let(:expected_data) { ::Ci::JobTraceChunk.find_by(job_id: job_id, chunk_index: chunk_index).data }

      it 'writes' do
        is_expected.to eq(data.length)

        expect(expected_data).to eq(data)
      end
    end

    context 'when data is nil' do
      let(:data) { nil }

      it { expect { subject }.to raise_error('Partial writing is not supported') }
    end
  end

  describe '#delete!' do
    subject { described_class.new(job_trace_chunk, params).delete! }

    context 'when job_trace_chunk exists' do
      before do
        described_class.new(job_trace_chunk, params).write!(data)
      end

      it 'deletes' do
        expect(::Ci::JobTraceChunk.exists?(job_id: job_id, chunk_index: chunk_index))
          .to be_truthy

        subject

        expect(::Ci::JobTraceChunk.exists?(job_id: job_id, chunk_index: chunk_index))
          .to be_falsy
      end
    end

    context 'when job_trace_chunk does not exist' do
      it 'raises an error' do
        expect { subject }.to raise_error('Could not find deletable record')
      end
    end
  end
end
