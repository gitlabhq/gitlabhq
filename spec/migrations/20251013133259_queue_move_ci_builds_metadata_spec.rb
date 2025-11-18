# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe QueueMoveCiBuildsMetadata, migration: :gitlab_ci, feature_category: :continuous_integration do
  let!(:batched_migration) { described_class::MIGRATION }

  let(:pipelines_table) { table(:p_ci_pipelines, primary_key: :id, database: :ci) }
  let(:builds_table) { table(:p_ci_builds, primary_key: :id, database: :ci) }
  let(:builds_metadata_table) { table(:p_ci_builds_metadata, primary_key: :id, database: :ci) }
  let(:pipeline_a) { pipelines_table.create!(partition_id: 100, project_id: 1) }
  let(:pipeline_b) { pipelines_table.create!(partition_id: 101, project_id: 2) }

  before do
    Ci::ApplicationRecord.connection.execute(<<~SQL)
      CREATE TABLE IF NOT EXISTS "gitlab_partitions_dynamic"."ci_builds_100"
        PARTITION OF "p_ci_builds" FOR VALUES IN (100);
      CREATE TABLE IF NOT EXISTS "gitlab_partitions_dynamic"."ci_builds_101"
        PARTITION OF "p_ci_builds" FOR VALUES IN (101);
      CREATE TABLE IF NOT EXISTS "gitlab_partitions_dynamic"."ci_builds_102"
        PARTITION OF "p_ci_builds" FOR VALUES IN (102);
    SQL

    builds_table.create!(partition_id: pipeline_a.partition_id, project_id: 1, commit_id: pipeline_a.id)
    builds_table.create!(partition_id: pipeline_b.partition_id, project_id: 2, commit_id: pipeline_b.id)
  end

  context 'when executed on .com' do
    before do
      allow(Gitlab).to receive(:com_except_jh?).and_return(true)
    end

    it 'schedules new batched migrations' do
      reversible_migration do |migration|
        migration.before -> {
          expect(batched_migration).not_to have_scheduled_batched_migration
        }

        migration.after -> {
          expect(batched_migration).to have_scheduled_batched_migration(
            gitlab_schema: :gitlab_ci,
            table_name: :p_ci_builds,
            column_name: :id,
            job_arguments: [:partition_id, [100]],
            batch_size: described_class::BATCH_SIZE,
            sub_batch_size: described_class::SUB_BATCH_SIZE
          )

          expect(batched_migration).to have_scheduled_batched_migration(
            gitlab_schema: :gitlab_ci,
            table_name: :p_ci_builds,
            column_name: :id,
            job_arguments: [:partition_id, [101]],
            batch_size: described_class::BATCH_SIZE,
            sub_batch_size: described_class::SUB_BATCH_SIZE
          )

          expect(batched_migration).not_to have_scheduled_batched_migration(
            gitlab_schema: :gitlab_ci,
            table_name: :p_ci_builds,
            column_name: :id,
            job_arguments: [:partition_id, [102]],
            batch_size: described_class::BATCH_SIZE,
            sub_batch_size: described_class::SUB_BATCH_SIZE
          )
        }
      end
    end
  end

  context 'when executed everywhere else' do
    it 'does not schedule new batched migrations' do
      reversible_migration do |migration|
        migration.before -> {
          expect(batched_migration).not_to have_scheduled_batched_migration
        }

        migration.after -> {
          expect(batched_migration).not_to have_scheduled_batched_migration
        }
      end
    end
  end
end
