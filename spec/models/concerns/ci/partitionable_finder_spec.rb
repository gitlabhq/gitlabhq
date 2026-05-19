# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::PartitionableFinder, feature_category: :continuous_integration do
  let_it_be(:project, freeze: true) { create(:project) }
  let_it_be(:pipeline, freeze: true) { create(:ci_pipeline, project: project) }

  describe 'Ci::Pipeline.find_by_id' do
    context 'when the record is in the current partition' do
      before do
        allow(Ci::Partition)
          .to receive(:current)
          .and_return(build_stubbed(:ci_partition, id: pipeline.partition_id))
      end

      it 'finds pipeline with partition pruning' do
        expect(Ci::Pipeline.find_by_id(pipeline.id)).to eq(pipeline)
      end

      it 'does only one query' do
        expect do
          Ci::Pipeline.find_by_id(pipeline.id)
        end.not_to exceed_query_limit(1).for_query(/SELECT.*p_ci_pipelines/)
      end
    end

    context 'when the record is not in the current partition' do
      before do
        allow(Ci::Partition)
          .to receive(:current)
          .and_return(build_stubbed(:ci_partition, id: non_existing_record_id))
      end

      context 'when the record is in the latest active partitions' do
        before do
          allow(Ci::Partition).to receive_message_chain(:with_status, :order, :limit, :pluck)
            .and_return([pipeline.partition_id])
        end

        it 'finds pipeline in active partitions and logs the fallback' do
          expect(Gitlab::AppLogger).to receive(:info).with(
            hash_including(
              message: 'Failed to find the record in the current partition',
              record_id: pipeline.id,
              'class_name' => 'Ci::Pipeline'
            )
          )

          expect(Ci::Pipeline.find_by_id(pipeline.id)).to eq(pipeline)
        end

        it 'does two queries' do
          expect do
            Ci::Pipeline.find_by_id(pipeline.id)
          end.not_to exceed_query_limit(2).for_query(/SELECT.*p_ci_pipelines/)
        end
      end

      context 'when the record is not in the latest active partitions' do
        before do
          allow(Ci::Partition).to receive_message_chain(:with_status, :order, :limit, :pluck)
            .and_return([non_existing_record_id])
        end

        it 'falls back on the full table and logs both fallbacks' do
          expect(Gitlab::AppLogger).to receive(:info).with(
            hash_including(
              message: 'Failed to find the record in the current partition',
              record_id: pipeline.id,
              'class_name' => 'Ci::Pipeline'
            )
          )
          expect(Gitlab::AppLogger).to receive(:info).with(
            hash_including(
              message: 'Failed to find the record in the latest active partitions',
              record_id: pipeline.id,
              'class_name' => 'Ci::Pipeline'
            )
          )

          expect(Ci::Pipeline.find_by_id(pipeline.id)).to eq(pipeline)
        end

        it 'does three queries' do
          expect do
            Ci::Pipeline.find_by_id(pipeline.id)
          end.not_to exceed_query_limit(3).for_query(/SELECT.*p_ci_pipelines/)
        end
      end
    end

    it 'returns nil when record not found' do
      result = Ci::Pipeline.find_by_id(non_existing_record_id)
      expect(result).to be_nil
    end
  end
end
