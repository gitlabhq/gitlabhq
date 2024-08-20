# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillPartitionIdCiPipelineConfig, feature_category: :continuous_integration do
  let(:ci_pipelines_table) { table(:ci_pipelines, primary_key: :id, database: :ci) }
  let(:ci_pipeline_config_table) { table(:ci_pipelines_config, database: :ci) }
  let!(:pipeline_1) { ci_pipelines_table.create!(id: 1, partition_id: 100, project_id: 1) }
  let!(:pipeline_2) { ci_pipelines_table.create!(id: 2, partition_id: 101, project_id: 1) }
  let!(:pipeline_3) { ci_pipelines_table.create!(id: 3, partition_id: 100, project_id: 1) }
  let!(:ci_pipeline_config_100) do
    ci_pipeline_config_table.create!(
      pipeline_id: pipeline_1.id,
      content: "content",
      partition_id: pipeline_1.partition_id
    )
  end

  let!(:ci_pipeline_config_101) do
    ci_pipeline_config_table.create!(
      pipeline_id: pipeline_2.id,
      content: "content",
      partition_id: pipeline_2.partition_id
    )
  end

  let!(:invalid_ci_pipeline_config) do
    ci_pipeline_config_table.create!(
      pipeline_id: pipeline_3.id,
      content: "content",
      partition_id: pipeline_1.partition_id
    )
  end

  let(:migration_attrs) do
    {
      start_id: ci_pipeline_config_table.minimum(:pipeline_id),
      end_id: ci_pipeline_config_table.maximum(:pipeline_id),
      batch_table: :ci_pipelines_config,
      batch_column: :pipeline_id,
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
    context 'when second partition does not exist' do
      it 'does not execute the migration' do
        expect { migration.perform }
          .not_to change { invalid_ci_pipeline_config.reload.partition_id }
      end
    end

    context 'when second partition exists' do
      before do
        pipeline_3.update!(partition_id: 101)
      end

      it 'fixes invalid records in the wrong the partition' do
        expect { migration.perform }
          .to not_change { ci_pipeline_config_100.reload.partition_id }
          .and not_change { ci_pipeline_config_101.reload.partition_id }
          .and change { invalid_ci_pipeline_config.reload.partition_id }
          .from(100)
          .to(101)
      end
    end
  end
end
