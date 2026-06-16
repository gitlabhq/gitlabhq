# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Preloaders::PipelinePreloader, feature_category: :continuous_integration do
  let_it_be(:project) { create(:project) }

  let_it_be_with_reload(:partition) { create(:ci_partition, id: 101) }

  let_it_be(:pipeline) do
    create(:ci_pipeline, project: project, partition_id: partition.id)
  end

  let_it_be(:other_pipeline) do
    create(:ci_pipeline, project: project, partition_id: partition.id)
  end

  let_it_be(:merge_request) do
    create(:merge_request, source_project: project, head_pipeline_id: pipeline.id)
  end

  let_it_be(:other_merge_request) do
    create(:merge_request, :unique_branches, source_project: project, head_pipeline_id: other_pipeline.id)
  end

  let_it_be(:mr_without_pipeline) do
    create(:merge_request, :unique_branches, source_project: project, head_pipeline_id: nil)
  end

  before do
    partition.update!(
      pipelines_id_range: [pipeline.id, other_pipeline.id].min...([pipeline.id, other_pipeline.id].max + 1)
    )
    Gitlab::Ci::Pipeline::PartitionCache.invalidate
  end

  subject(:preload) do
    described_class.new(
      records,
      association: :head_pipeline,
      foreign_key: :head_pipeline_id
    ).preload_all
  end

  describe '#preload_all' do
    context 'when records have head_pipeline_ids' do
      let(:records) { [merge_request, other_merge_request] }

      it 'populates the association cache so subsequent reads do not query' do
        preload

        expect do
          expect(records.map(&:head_pipeline)).to eq([pipeline, other_pipeline])
        end.not_to exceed_query_limit(0).for_query(/SELECT.*p_ci_pipelines/)
      end

      it 'marks the association as loaded' do
        preload

        records.each do |record|
          expect(record.association(:head_pipeline)).to be_loaded
        end
      end
    end

    context 'when a record has a nil head_pipeline_id' do
      let(:records) { [merge_request, mr_without_pipeline] }

      it 'sets the target to nil and marks the association loaded for the nil case' do
        preload

        expect(merge_request.association(:head_pipeline)).to be_loaded
        expect(merge_request.head_pipeline).to eq(pipeline)

        expect(mr_without_pipeline.association(:head_pipeline)).to be_loaded
        expect(mr_without_pipeline.head_pipeline).to be_nil
      end
    end

    context 'when the records list is empty' do
      let(:records) { [] }

      it 'does not raise and issues no pipeline queries' do
        expect do
          preload
        end.not_to exceed_query_limit(0).for_query(/SELECT.*p_ci_pipelines/)
      end
    end

    context 'when the referenced pipeline no longer exists' do
      let_it_be(:mr_with_missing_pipeline) do
        mr = create(:merge_request, :unique_branches, source_project: project)
        mr.update_column(:head_pipeline_id, non_existing_record_id)
        mr
      end

      let(:records) { [mr_with_missing_pipeline] }

      it 'sets the target to nil and marks the association loaded' do
        preload

        expect(mr_with_missing_pipeline.association(:head_pipeline)).to be_loaded
        expect(mr_with_missing_pipeline.head_pipeline).to be_nil
      end
    end
  end
end
