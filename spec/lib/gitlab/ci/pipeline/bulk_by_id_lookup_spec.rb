# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Pipeline::BulkByIdLookup, feature_category: :continuous_integration do
  let_it_be(:project) { create(:project) }

  let_it_be_with_reload(:partition) { create(:ci_partition, id: 101) }
  let_it_be_with_reload(:other_partition) { create(:ci_partition, id: 102) }

  let_it_be(:pipeline) do
    create(:ci_pipeline, project: project, partition_id: partition.id)
  end

  let_it_be(:other_pipeline) do
    create(:ci_pipeline, project: project, partition_id: other_partition.id)
  end

  before do
    Gitlab::Ci::Pipeline::PartitionCache.invalidate
  end

  describe '#execute' do
    context 'when ids is empty' do
      it 'returns an empty hash without issuing queries' do
        expect do
          expect(described_class.new([]).execute).to eq({})
        end.not_to exceed_query_limit(0).for_query(/SELECT.*p_ci_pipelines/)
      end
    end

    context 'when ids are covered by cached partition ranges' do
      before do
        partition.update!(pipelines_id_range: pipeline.id...(pipeline.id + 1))
        other_partition.update!(pipelines_id_range: other_pipeline.id...(other_pipeline.id + 1))
        Gitlab::Ci::Pipeline::PartitionCache.invalidate
      end

      subject(:execute) { described_class.new([pipeline.id, other_pipeline.id]).execute }

      it 'returns a hash keyed by pipeline id' do
        expect(execute).to eq(
          pipeline.id => pipeline,
          other_pipeline.id => other_pipeline
        )
      end

      it 'issues a single SELECT on p_ci_pipelines' do
        expect do
          execute
        end.not_to exceed_query_limit(1).for_query(/SELECT.*p_ci_pipelines/)
      end
    end

    context 'when no cached range covers the ids' do
      subject(:execute) { described_class.new([pipeline.id, other_pipeline.id]).execute }

      it 'logs the cache miss and falls back to a full scan' do
        expect(Gitlab::AppLogger).to receive(:info).with(
          hash_including(
            message: 'PartitionCache has no range covering pipeline ids, falling back to full scan',
            missing_record_count: 2,
            'class_name' => 'Ci::Pipeline'
          )
        )
        expect(Gitlab::AppLogger).to receive(:info).with(
          hash_including(
            message: 'Partition-pruned query missed, falling back to full scan',
            missing_record_count: 2
          )
        )

        expect(execute).to eq(
          pipeline.id => pipeline,
          other_pipeline.id => other_pipeline
        )
      end
    end

    context 'when the cache covers only some ids' do
      before do
        partition.update!(pipelines_id_range: pipeline.id...(pipeline.id + 1))
        Gitlab::Ci::Pipeline::PartitionCache.invalidate
      end

      subject(:execute) { described_class.new([pipeline.id, other_pipeline.id]).execute }

      it 'finds cached ids via partition pruning and the rest via full scan' do
        expect(Gitlab::AppLogger).to receive(:info).with(
          hash_including(
            message: 'Partition-pruned query missed, falling back to full scan',
            missing_record_count: 1
          )
        )

        expect(execute).to eq(
          pipeline.id => pipeline,
          other_pipeline.id => other_pipeline
        )
      end
    end

    context 'when an id does not exist anywhere' do
      subject(:execute) { described_class.new([non_existing_record_id]).execute }

      it 'omits unknown ids from the result' do
        expect(execute).to eq({})
      end
    end

    context 'when duplicate ids are passed in' do
      before do
        partition.update!(pipelines_id_range: pipeline.id...(pipeline.id + 1))
        Gitlab::Ci::Pipeline::PartitionCache.invalidate
      end

      subject(:execute) { described_class.new([pipeline.id, pipeline.id]).execute }

      it 'returns a single entry' do
        expect(execute).to eq(pipeline.id => pipeline)
      end
    end

    context 'when nil ids are passed in' do
      before do
        partition.update!(pipelines_id_range: pipeline.id...(pipeline.id + 1))
        Gitlab::Ci::Pipeline::PartitionCache.invalidate
      end

      subject(:execute) { described_class.new([nil, pipeline.id, nil]).execute }

      it 'filters out nils' do
        expect(execute).to eq(pipeline.id => pipeline)
      end
    end
  end
end
