# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Pipeline::ByIdLookup, feature_category: :continuous_integration do
  let_it_be(:project) { create(:project) }
  let_it_be_with_reload(:partition) { create(:ci_partition, id: 102) }
  let_it_be(:pipeline) { create(:ci_pipeline, project: project, partition_id: partition.id) }

  let(:scope) { Ci::Pipeline.all }

  before do
    Gitlab::Ci::Pipeline::PartitionCache.invalidate
  end

  describe '#execute' do
    context 'when id is nil' do
      it 'returns nil without querying or logging' do
        expect(Gitlab::AppLogger).not_to receive(:info)

        expect(described_class.new(scope, nil).execute).to be_nil
      end
    end

    context 'when id is a blank string' do
      it 'returns nil' do
        expect(described_class.new(scope, '').execute).to be_nil
      end
    end

    context 'when a partition range covers the pipeline id' do
      before do
        partition.update!(pipelines_id_range: pipeline.id...(pipeline.id + 1))
        Gitlab::Ci::Pipeline::PartitionCache.invalidate
      end

      it 'returns the pipeline via the partition-pruned query without logging' do
        expect(Gitlab::AppLogger).not_to receive(:info)

        expect(described_class.new(scope, pipeline.id).execute).to eq(pipeline)
      end

      it 'issues a single SELECT on p_ci_pipelines' do
        expect do
          described_class.new(scope, pipeline.id).execute
        end.not_to exceed_query_limit(1).for_query(/SELECT.*p_ci_pipelines/)
      end
    end

    context 'when a partition range covers the id but no pipeline matches' do
      let(:missing_id) { non_existing_record_id }

      before do
        partition.update!(pipelines_id_range: missing_id...(missing_id + 1))
        Gitlab::Ci::Pipeline::PartitionCache.invalidate
      end

      it 'returns nil and logs the full-table-scan fallback' do
        expect(Gitlab::AppLogger).to receive(:info).with(
          hash_including(
            message: 'Partition-pruned query missed, falling back to full scan',
            record_id: missing_id,
            'class_name' => 'Ci::Pipeline'
          )
        )

        expect(described_class.new(scope, missing_id).execute).to be_nil
      end
    end

    context 'when no partition range covers the id' do
      it 'logs the cache miss and the full-table-scan fallback, then returns the pipeline' do
        expect(Gitlab::AppLogger).to receive(:info).with(
          hash_including(
            message: 'PartitionCache has no range covering pipeline id, falling back to full scan',
            record_id: pipeline.id,
            'class_name' => 'Ci::Pipeline'
          )
        )
        expect(Gitlab::AppLogger).to receive(:info).with(
          hash_including(
            message: 'Partition-pruned query missed, falling back to full scan',
            record_id: pipeline.id,
            'class_name' => 'Ci::Pipeline'
          )
        )

        expect(described_class.new(scope, pipeline.id).execute).to eq(pipeline)
      end

      it 'returns nil when the record does not exist either' do
        allow(Gitlab::AppLogger).to receive(:info)

        expect(described_class.new(scope, non_existing_record_id).execute).to be_nil
      end
    end

    context 'with a chained scope' do
      before do
        partition.update!(pipelines_id_range: pipeline.id...(pipeline.id + 1))
        Gitlab::Ci::Pipeline::PartitionCache.invalidate
      end

      it 'passes the chained relation through to find_by' do
        ordered_scope = Ci::Pipeline.order(id: :desc)

        expect(ordered_scope).to receive(:find_by).with(
          id: pipeline.id, partition_id: array_including(partition.id)
        ).and_call_original

        expect(described_class.new(ordered_scope, pipeline.id).execute).to eq(pipeline)
      end
    end
  end
end
