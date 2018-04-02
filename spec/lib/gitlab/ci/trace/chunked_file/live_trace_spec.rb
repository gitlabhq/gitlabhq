require 'spec_helper'

describe Gitlab::Ci::Trace::ChunkedFile::LiveTrace, :clean_gitlab_redis_cache do
  include ChunkedIOHelpers

  let(:chunked_io) { described_class.new(job_id, nil, mode) }
  let(:job) { create(:ci_build) }
  let(:job_id) { job.id }
  let(:mode) { 'rb' }

  let(:chunk_stores) do
    [Gitlab::Ci::Trace::ChunkedFile::ChunkStore::Redis,
      Gitlab::Ci::Trace::ChunkedFile::ChunkStore::Database]
  end

  describe 'ChunkStores are Redis and Database', :partial_support do
    it_behaves_like 'ChunkedIO shared tests'
  end

  describe '.exist?' do
    subject { described_class.exist?(job_id) }

    context 'when a chunk exists in a store' do
      before do
        fill_trace_to_chunks(sample_trace_raw)
      end

      it { is_expected.to be_truthy }
    end

    context 'when chunks do not exists in any store' do
      it { is_expected.to be_falsey }
    end
  end

  describe '#truncate' do
    subject { chunked_io.truncate(offset) }

    let(:mode) { 'a+b' }

    before do
      fill_trace_to_chunks(sample_trace_raw)
    end

    context 'when offset is 0' do
      let(:offset) { 0 }

      it 'deletes all chunks' do
        expect { subject }.to change { described_class.exist?(job_id) }.from(true).to(false)
      end
    end

    context 'when offset is size' do
      let(:offset) { sample_trace_raw.length }

      it 'does nothing' do
        expect { subject }.not_to change { described_class.exist?(job_id) }
      end
    end

    context 'when offset is else' do
      let(:offset) { 10 }

      it 'raises an error' do
        expect { subject }.to raise_error('Unexpected operation')
      end
    end
  end

  describe '#delete' do
    subject { chunked_io.delete }

    context 'when a chunk exists in a store' do
      before do
        fill_trace_to_chunks(sample_trace_raw)
      end

      it 'deletes' do
        expect { subject }.to change { described_class.exist?(job_id) }.from(true).to(false)
      end
    end

    context 'when chunks do not exists in any store' do
      it 'deletes' do
        expect { subject }.not_to change { described_class.exist?(job_id) }
      end
    end
  end
end
