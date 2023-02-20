# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe FixPartitionIdsOnCiSourcesPipelines, migration: :gitlab_ci, feature_category: :continuous_integration do
  let(:sources_pipelines) { table(:ci_sources_pipelines, database: :ci) }

  before do
    sources_pipelines.insert_all!([
      { partition_id: 100, source_partition_id: 100 },
      { partition_id: 100, source_partition_id: 101 },
      { partition_id: 101, source_partition_id: 100 },
      { partition_id: 101, source_partition_id: 101 }
    ])
  end

  describe '#up' do
    context 'when on sass' do
      before do
        allow(Gitlab).to receive(:com?).and_return(true)
      end

      it 'fixes partition_id and source_partition_id' do
        expect { migrate! }.not_to raise_error

        expect(sources_pipelines.where(partition_id: 100).count).to eq(4)
        expect(sources_pipelines.where(partition_id: 101).count).to eq(0)
        expect(sources_pipelines.where(source_partition_id: 100).count).to eq(4)
        expect(sources_pipelines.where(source_partition_id: 101).count).to eq(0)
      end
    end

    context 'when on self managed' do
      it 'does not change partition_id or source_partition_id' do
        expect { migrate! }.not_to raise_error

        expect(sources_pipelines.where(partition_id: 100).count).to eq(2)
        expect(sources_pipelines.where(partition_id: 100).count).to eq(2)
        expect(sources_pipelines.where(source_partition_id: 101).count).to eq(2)
        expect(sources_pipelines.where(source_partition_id: 101).count).to eq(2)
      end
    end
  end
end
