# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillPartitionIdCiPipelineChatData,
  feature_category: :continuous_integration do
  let(:ci_pipelines_table) { table(:ci_pipelines, database: :ci) }
  let(:ci_pipeline_chat_data_table) { table(:ci_pipeline_chat_data, database: :ci) }
  let!(:pipeline1) { ci_pipelines_table.create!(id: 1, partition_id: 100) }
  let!(:pipeline2) { ci_pipelines_table.create!(id: 2, partition_id: 101) }
  let!(:invalid_ci_pipeline_chat_data) do
    ci_pipeline_chat_data_table.create!(
      id: 1,
      pipeline_id: pipeline1.id,
      chat_name_id: 1,
      response_url: '',
      partition_id: pipeline1.partition_id
    )
  end

  let!(:valid_ci_pipeline_chat_data) do
    ci_pipeline_chat_data_table.create!(
      id: 2,
      pipeline_id: pipeline2.id,
      chat_name_id: 2,
      response_url: '',
      partition_id: pipeline2.partition_id
    )
  end

  let(:migration_attrs) do
    {
      start_id: ci_pipeline_chat_data_table.minimum(:id),
      end_id: ci_pipeline_chat_data_table.maximum(:id),
      batch_table: :ci_pipeline_chat_data,
      batch_column: :id,
      sub_batch_size: 1,
      pause_ms: 0,
      connection: Ci::ApplicationRecord.connection
    }
  end

  let!(:migration) { described_class.new(**migration_attrs) }

  describe '#perform' do
    context 'when second partition does not exist' do
      it 'does not execute the migration' do
        expect { migration.perform }
          .not_to change { invalid_ci_pipeline_chat_data.reload.partition_id }
      end
    end

    context 'when second partition exists' do
      before do
        allow(migration).to receive(:uses_multiple_partitions?).and_return(true)
        pipeline1.update!(partition_id: 101)
      end

      it 'fixes invalid records in the wrong the partition' do
        expect { migration.perform }
          .to change { invalid_ci_pipeline_chat_data.reload.partition_id }
          .from(100)
          .to(101)
      end
    end
  end
end
