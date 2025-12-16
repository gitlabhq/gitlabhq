# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe QueueBackfillPCiPipelineIids, migration: :gitlab_ci, feature_category: :continuous_integration do
  let!(:batched_migration) { described_class::MIGRATION }
  let(:pipelines_table) { table(:p_ci_pipelines, primary_key: :id, database: :ci) }

  before do
    Ci::ApplicationRecord.connection.execute(<<~SQL)
      CREATE TABLE IF NOT EXISTS "gitlab_partitions_dynamic"."ci_pipelines_100"
        PARTITION OF "p_ci_pipelines" FOR VALUES IN (100);
      CREATE TABLE IF NOT EXISTS "gitlab_partitions_dynamic"."ci_pipelines_101"
        PARTITION OF "p_ci_pipelines" FOR VALUES IN (101);
      CREATE TABLE IF NOT EXISTS "gitlab_partitions_dynamic"."ci_pipelines_102"
        PARTITION OF "p_ci_pipelines" FOR VALUES IN (102);
    SQL

    pipelines_table.create!(partition_id: 100, project_id: 1)
    pipelines_table.create!(partition_id: 101, project_id: 2)
  end

  it 'schedules new batched migrations' do
    reversible_migration do |migration|
      migration.before -> {
        expect(batched_migration).not_to have_scheduled_batched_migration
      }

      migration.after -> {
        expect(batched_migration).to have_scheduled_batched_migration(
          gitlab_schema: :gitlab_ci,
          table_name: "gitlab_partitions_dynamic.ci_pipelines_100",
          column_name: :id,
          job_arguments: [],
          batch_size: described_class::BATCH_SIZE,
          sub_batch_size: described_class::SUB_BATCH_SIZE
        )

        expect(batched_migration).to have_scheduled_batched_migration(
          gitlab_schema: :gitlab_ci,
          table_name: "gitlab_partitions_dynamic.ci_pipelines_101",
          column_name: :id,
          job_arguments: [],
          batch_size: described_class::BATCH_SIZE,
          sub_batch_size: described_class::SUB_BATCH_SIZE
        )

        expect(batched_migration).not_to have_scheduled_batched_migration(
          gitlab_schema: :gitlab_ci,
          table_name: "gitlab_partitions_dynamic.ci_pipelines_102",
          column_name: :id,
          job_arguments: [],
          batch_size: described_class::BATCH_SIZE,
          sub_batch_size: described_class::SUB_BATCH_SIZE
        )
      }
    end
  end
end
