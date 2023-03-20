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
  end
end
