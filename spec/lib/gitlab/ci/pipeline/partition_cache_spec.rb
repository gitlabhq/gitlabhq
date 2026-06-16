# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Pipeline::PartitionCache, feature_category: :continuous_integration do
  let_it_be(:lower_partition, freeze: false) { create(:ci_partition, pipelines_id_range: 100...200) }
  let_it_be(:upper_partition, freeze: false) { create(:ci_partition, pipelines_id_range: (200...)) }

  before do
    described_class.invalidate
  end

  describe '.partition_ids_for' do
    subject(:result) { described_class.partition_ids_for(pipeline_ids) }

    context 'when a scalar id falls inside a closed range' do
      let(:pipeline_ids) { 150 }

      it { is_expected.to contain_exactly(lower_partition.id) }
    end

    context 'when a scalar id falls inside an open-ended range' do
      let(:pipeline_ids) { 1_000_000 }

      it { is_expected.to contain_exactly(upper_partition.id) }
    end

    context 'when an array of ids spans different partitions' do
      let(:pipeline_ids) { [150, 1_000_000] }

      it { is_expected.to contain_exactly(lower_partition.id, upper_partition.id) }
    end

    context 'when an array of ids all fall in the same partition' do
      let(:pipeline_ids) { [150, 175] }

      it { is_expected.to contain_exactly(lower_partition.id) }
    end

    context 'when no partition tracks the id' do
      let(:pipeline_ids) { 50 }

      it { is_expected.to be_empty }
    end

    context 'when the input is nil' do
      let(:pipeline_ids) { nil }

      it { is_expected.to be_empty }
    end

    context 'when the input is an empty array' do
      let(:pipeline_ids) { [] }

      it { is_expected.to be_empty }
    end

    context 'when the array contains nil entries' do
      let(:pipeline_ids) { [nil, 150, nil] }

      it 'ignores nils and matches the remaining ids' do
        expect(result).to contain_exactly(lower_partition.id)
      end
    end
  end

  describe '.ranges (caching behaviour)' do
    it 'caches the result in the request store (no DB hit on second call)' do
      described_class.partition_ids_for(150) # warm the cache

      expect(::Ci::Partition).not_to receive(:where)

      described_class.partition_ids_for(150)
    end

    it 'populates Redis on the first DB hit' do
      described_class.partition_ids_for(150) # triggers DB + Redis SET

      Gitlab::SafeRequestStore.delete(described_class::CACHE_KEY)

      # Second call should read from Redis, not the DB
      expect(::Ci::Partition).not_to receive(:where)

      described_class.partition_ids_for(150)
    end
  end

  describe '.invalidate' do
    it 'clears the request store so the next call re-fetches' do
      described_class.partition_ids_for(150) # warm request store

      described_class.invalidate

      expect(Gitlab::SafeRequestStore.exist?(described_class::CACHE_KEY)).to be(false)
    end

    it 'clears Redis so the next call re-fetches from the DB' do
      described_class.partition_ids_for(150) # warm Redis

      described_class.invalidate

      Gitlab::Redis::SharedState.with do |redis|
        expect(redis.get(described_class::CACHE_KEY)).to be_nil
      end
    end

    it 'reflects updated ranges after invalidation' do
      described_class.ranges # warm cache

      lower_partition.update!(pipelines_id_range: 100...180)
      described_class.invalidate

      ranges = described_class.ranges
      expect(ranges[lower_partition.id]).to eq(100...180)
    end
  end
end
