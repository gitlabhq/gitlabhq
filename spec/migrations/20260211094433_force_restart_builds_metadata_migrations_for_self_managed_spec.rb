# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe ForceRestartBuildsMetadataMigrationsForSelfManaged, migration: :gitlab_ci,
  feature_category: :continuous_integration do
  describe '#up', :aggregate_failures do
    let!(:failed_migration) do
      Gitlab::Database::BackgroundMigration::BatchedMigration.create!(
        job_class_name: described_class::MIGRATION,
        table_name: 'gitlab_partitions_dynamic.ci_builds_100',
        column_name: :id,
        job_arguments: [:partition_id, [100]],
        interval: 120,
        min_value: 1,
        max_value: 100,
        batch_size: 1000,
        sub_batch_size: 200,
        pause_ms: 100,
        gitlab_schema: :gitlab_ci,
        status: 4
      )
    end

    let!(:successful_migration) do
      Gitlab::Database::BackgroundMigration::BatchedMigration.create!(
        job_class_name: described_class::MIGRATION,
        table_name: 'gitlab_partitions_dynamic.ci_builds_101',
        column_name: :id,
        job_arguments: [:partition_id, [101]],
        interval: 120,
        min_value: 1,
        max_value: 100,
        batch_size: 1000,
        sub_batch_size: 200,
        pause_ms: 100,
        gitlab_schema: :gitlab_ci,
        status: 3
      )
    end

    before do
      failed_migration.batched_jobs.create!(
        batch_size: 1000, sub_batch_size: 100, min_value: 1, max_value: 100, attempts: 5
      )

      successful_migration.batched_jobs.create!(
        batch_size: 1000, sub_batch_size: 100, min_value: 100, max_value: 200, attempts: 2
      )
    end

    it 'restarts failed batched migrations and skips non-failed ones' do
      migrate!

      expect(failed_migration.reload.status).to eq(1)
      expect(successful_migration.reload.status).to eq(3)

      expect(failed_migration.batched_jobs.where('attempts > 0').count).to eq(0)
      expect(successful_migration.batched_jobs.where('attempts > 0').count).to eq(1)
    end
  end

  describe '#down' do
    it 'is a no-op' do
      expect { schema_migrate_down! }.not_to raise_error
    end
  end
end
