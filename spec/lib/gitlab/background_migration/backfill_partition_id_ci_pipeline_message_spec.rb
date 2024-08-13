# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillPartitionIdCiPipelineMessage, feature_category: :ci_scaling do
  let(:ci_pipelines_table) { table(:ci_pipelines, database: :ci) }
  let(:ci_pipeline_messages_table) { table(:ci_pipeline_messages, database: :ci) }
  let!(:pipeline_1) { ci_pipelines_table.create!(id: 1, partition_id: 100, project_id: 1) }
  let!(:pipeline_2) { ci_pipelines_table.create!(id: 2, partition_id: 101, project_id: 1) }
  let!(:pipeline_3) { ci_pipelines_table.create!(id: 3, partition_id: 100, project_id: 1) }
  let!(:ci_pipeline_messages_100) do
    ci_pipeline_messages_table.create!(
      content: 'content',
      pipeline_id: pipeline_1.id,
      partition_id: pipeline_1.partition_id
    )
  end

  let!(:ci_pipeline_messages_101) do
    ci_pipeline_messages_table.create!(
      content: 'content',
      pipeline_id: pipeline_2.id,
      partition_id: pipeline_2.partition_id
    )
  end

  let!(:invalid_ci_pipeline_messages) do
    ci_pipeline_messages_table.create!(
      content: 'content',
      pipeline_id: pipeline_3.id,
      partition_id: pipeline_3.partition_id
    )
  end

  let(:migration_attrs) do
    {
      start_id: ci_pipeline_messages_table.minimum(:id),
      end_id: ci_pipeline_messages_table.maximum(:id),
      batch_table: :ci_pipeline_messages,
      batch_column: :id,
      sub_batch_size: 1,
      pause_ms: 0,
      connection: connection
    }
  end

  let!(:migration) { described_class.new(**migration_attrs) }
  let(:connection) { Ci::ApplicationRecord.connection }

  around do |example|
    connection.transaction do
      connection.execute(<<~SQL)
        ALTER TABLE ci_pipelines DISABLE TRIGGER ALL;
      SQL

      example.run

      connection.execute(<<~SQL)
        ALTER TABLE ci_pipelines ENABLE TRIGGER ALL;
      SQL
    end
  end

  describe '#perform' do
    context 'when there are no invalid records' do
      it 'does not execute the migration' do
        expect { migration.perform }
          .not_to change { invalid_ci_pipeline_messages.reload.partition_id }
      end
    end

    context 'when second partition exists' do
      before do
        pipeline_3.update!(partition_id: 101)
      end

      it 'fixes invalid records in the wrong the partition' do
        expect { migration.perform }
          .to not_change { ci_pipeline_messages_100.reload.partition_id }
          .and not_change { ci_pipeline_messages_101.reload.partition_id }
          .and change { invalid_ci_pipeline_messages.reload.partition_id }
          .from(100)
          .to(101)
      end
    end
  end
end
