# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::BuildTraceChunkFlushWorker, feature_category: :continuous_integration do
  let(:data) { 'x' * Ci::BuildTraceChunk::CHUNK_SIZE }

  let(:chunk) do
    create(:ci_build_trace_chunk, :redis_with_data, initial_data: data)
  end

  it_behaves_like 'worker with data consistency', described_class, data_consistency: :sticky

  it 'has a deduplicate strategy' do
    expect(described_class.get_deduplicate_strategy).to eq(:until_executed)
  end

  it 'has a concurrency limit' do
    expect(described_class.get_max_concurrency_limit_percentage).to eq(0.45)
  end

  it 'disables retry' do
    expect(described_class.sidekiq_options['retry']).to be(false)
  end

  it 'migrates chunk to a permanent store' do
    expect(chunk).to be_live

    described_class.new.perform(chunk.id)

    expect(chunk.reload).to be_migrated
  end

  # It's OK to remove this test in future if we need to load the associated Ci::Build for a legitimate reason.
  # See https://gitlab.com/gitlab-org/gitlab/-/merge_requests/227700 for context.
  it 'does not load the build' do
    chunk_id = chunk.id

    expect { described_class.new.perform(chunk_id) }.not_to exceed_query_limit(0).for_query(/p_ci_builds/)
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
