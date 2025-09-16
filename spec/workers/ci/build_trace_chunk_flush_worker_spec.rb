# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::BuildTraceChunkFlushWorker, feature_category: :continuous_integration do
  let(:data) { 'x' * Ci::BuildTraceChunk::CHUNK_SIZE }

  let(:chunk) do
    create(:ci_build_trace_chunk, :redis_with_data, initial_data: data)
  end

  it 'migrates chunk to a permanent store' do
    expect(chunk).to be_live

    described_class.new.perform(chunk.id)

    expect(chunk.reload).to be_migrated
  end

  describe '#perform' do
    it_behaves_like 'an idempotent worker' do
      let(:job_args) { [chunk.id] }

      it 'migrates build trace chunk to a safe store' do
        subject

        expect(chunk.reload).to be_migrated
      end
    end

    # rubocop: disable RSpec/AnyInstanceOf -- next_instance_of will not work here
    context 'when save operation fails' do
      it 'preserves Redis data on first failure and completes migration on retry' do
        expect(chunk).to be_live

        allow_any_instance_of(Ci::BuildTraceChunk).to receive(:save!).and_return(false)

        # First run save! fails so we should still have redis data
        expect do
          described_class.new.perform(chunk.id)
        end.to raise_error(Ci::BuildTraceChunk::FailedToPersistDataError)

        chunk.reload
        expect(chunk).to be_live
        expect(chunk).not_to be_migrated

        redis_data = Ci::BuildTraceChunks::RedisTraceChunks.new.data(chunk)
        expect(redis_data).to eq(data)

        allow_any_instance_of(Ci::BuildTraceChunk).to receive(:save!).and_call_original

        # Second run it recovers
        described_class.new.perform(chunk.id)

        chunk.reload
        expect(chunk).to be_migrated
        expect(chunk).not_to be_live

        redis_data = Ci::BuildTraceChunks::RedisTraceChunks.new.data(chunk)
        expect(redis_data).to be_nil
      end
    end
    # rubocop: enable RSpec/AnyInstanceOf
  end
end
