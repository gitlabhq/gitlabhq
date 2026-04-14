# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::ExpirePipelineCacheWorker, :use_clean_rails_redis_caching,
  feature_category: :continuous_integration do
  let_it_be(:pipeline, freeze: true) { create(:ci_pipeline) }

  let(:worker) { described_class.new }

  describe 'sidekiq options' do
    it 'is idempotent' do
      expect(described_class).to be_idempotent
    end

    it 'has high urgency' do
      expect(described_class.get_urgency).to eq(:high)
    end

    it 'deduplicates until executed' do
      expect(described_class.deduplication_enabled?).to be_truthy
      expect(described_class.get_deduplicate_strategy).to eq(:until_executed)
    end
  end

  it_behaves_like 'an idempotent worker' do
    let(:job_args) { [pipeline.id] }
  end

  it_behaves_like 'worker with data consistency', described_class, data_consistency: :sticky

  describe '#perform' do
    subject(:perform) { worker.perform(pipeline.id, { 'partition_id' => pipeline.partition_id }) }

    it 'executes Ci::ExpirePipelineCacheService' do
      expect_next_instance_of(Ci::ExpirePipelineCacheService) do |service|
        expect(service).to receive(:execute).with(pipeline).and_call_original
      end

      perform
    end

    context 'when pipeline does not exist' do
      subject(:perform) { worker.perform(non_existing_record_id) }

      it 'does not error' do
        expect(Ci::ExpirePipelineCacheService).not_to receive(:new)

        expect { perform }.not_to raise_error
      end
    end
  end
end
