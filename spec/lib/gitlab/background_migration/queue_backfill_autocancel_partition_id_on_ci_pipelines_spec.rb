# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::QueueBackfillAutocancelPartitionIdOnCiPipelines,
  :suppress_partitioning_routing_analyzer,
  feature_category: :continuous_integration,
  migration: :gitlab_ci,
  schema: 20240704155541 do
  let(:ci_pipelines_table) { table(:ci_pipelines, primary_key: :id, database: :ci) }

  let!(:pipeline_1) { ci_pipelines_table.create!(partition_id: 100) }
  let!(:pipeline_3) { ci_pipelines_table.create!(partition_id: 101) }
  let!(:pipeline_2) { ci_pipelines_table.create!(partition_id: 100, auto_canceled_by_id: pipeline_3.id) }
  let!(:pipeline_4) { ci_pipelines_table.create!(partition_id: 101, auto_canceled_by_id: pipeline_2.id) }

  let(:migration_attrs) do
    {
      start_id: ci_pipelines_table.minimum(:id),
      end_id: ci_pipelines_table.maximum(:id),
      batch_table: :ci_pipelines,
      batch_column: :id,
      sub_batch_size: 2,
      pause_ms: 0,
      connection: Ci::ApplicationRecord.connection
    }
  end

  let!(:migration) { described_class.new(**migration_attrs) }

  describe '#perform' do
    it 'backfills auto_canceled_by_partition_id' do
      expect { migration.perform }
        .to not_change { pipeline_1.reload.auto_canceled_by_partition_id }
        .and not_change { pipeline_3.reload.auto_canceled_by_partition_id }
        .and change { pipeline_2.reload.auto_canceled_by_partition_id }.from(nil).to(101)
        .and change { pipeline_4.reload.auto_canceled_by_partition_id }.from(nil).to(100)
    end
  end
end
