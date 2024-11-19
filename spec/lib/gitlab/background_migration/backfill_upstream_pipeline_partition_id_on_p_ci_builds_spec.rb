# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillUpstreamPipelinePartitionIdOnPCiBuilds,
  :suppress_partitioning_routing_analyzer,
  feature_category: :continuous_integration do
  let(:pipelines_table) { table(:ci_pipelines, primary_key: :id, database: :ci) }

  let(:jobs_table) { partitioned_table(:p_ci_builds, database: :ci) }

  let!(:pipeline_1) { pipelines_table.create!(id: 1, partition_id: 100, project_id: 1) }
  let!(:pipeline_2) { pipelines_table.create!(id: 2, partition_id: 100, project_id: 1) }
  let!(:pipeline_3) { pipelines_table.create!(id: 3, partition_id: 100, project_id: 1) }

  let!(:job_1) { jobs_table.create!(commit_id: pipeline_1.id, partition_id: pipeline_1.partition_id, project_id: 1) }
  let!(:job_2) { jobs_table.create!(commit_id: pipeline_2.id, partition_id: pipeline_2.partition_id, project_id: 1) }
  let!(:job_3) { jobs_table.create!(commit_id: pipeline_2.id, partition_id: pipeline_2.partition_id, project_id: 1) }

  let(:migration_attrs) do
    {
      start_id: jobs_table.minimum(:upstream_pipeline_id),
      end_id: jobs_table.maximum(:upstream_pipeline_id),
      batch_table: :p_ci_builds,
      batch_column: :upstream_pipeline_id,
      sub_batch_size: 2,
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
    before do
      job_2.update!(upstream_pipeline_id: pipeline_1.id)
      job_3.update!(upstream_pipeline_id: pipeline_3.id)
      pipeline_3.update!(partition_id: 101)
    end

    it 'backfills upstream_pipeline_partition_id' do
      expect { migration.perform }
        .to not_change { job_1.reload.upstream_pipeline_partition_id }
        .and change { job_2.reload.upstream_pipeline_partition_id }.from(nil).to(100)
        .and change { job_3.reload.upstream_pipeline_partition_id }.from(nil).to(101)
    end
  end
end
