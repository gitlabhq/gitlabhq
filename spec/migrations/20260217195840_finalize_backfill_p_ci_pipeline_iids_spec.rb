# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe FinalizeBackfillPCiPipelineIids, migration: :gitlab_ci, feature_category: :continuous_integration do
  let(:job_class_name) { 'BackfillPCiPipelineIids' }
  let(:batched_background_migrations_table) { table(:batched_background_migrations) }

  let!(:batched_migration_100) do
    batched_background_migrations_table.create!(
      job_class_name: job_class_name,
      table_name: 'gitlab_partitions_dynamic.ci_pipelines_100',
      column_name: :id,
      job_arguments: [],
      batch_size: 10_000,
      sub_batch_size: 1_000,
      interval: 10,
      gitlab_schema: :gitlab_ci,
      min_value: 1,
      max_value: 2,
      status: 3 # Finished status
    )
  end

  let!(:batched_migration_101) do
    batched_background_migrations_table.create!(
      job_class_name: job_class_name,
      table_name: 'gitlab_partitions_dynamic.ci_pipelines_101',
      column_name: :id,
      job_arguments: [],
      batch_size: 10_000,
      sub_batch_size: 1_000,
      interval: 10,
      gitlab_schema: :gitlab_ci,
      min_value: 1,
      max_value: 2,
      status: 3 # Finished status
    )
  end

  before do
    Ci::ApplicationRecord.connection.execute(<<~SQL)
      CREATE TABLE IF NOT EXISTS "gitlab_partitions_dynamic"."ci_pipelines_100"
        PARTITION OF "p_ci_pipelines" FOR VALUES IN (100);
      CREATE TABLE IF NOT EXISTS "gitlab_partitions_dynamic"."ci_pipelines_101"
        PARTITION OF "p_ci_pipelines" FOR VALUES IN (101);
      CREATE TABLE IF NOT EXISTS "gitlab_partitions_dynamic"."ci_pipelines_102"
        PARTITION OF "p_ci_pipelines" FOR VALUES IN (102);
    SQL
  end

  it 'finalizes existing BBMs of the given job class' do
    expect_next_instance_of(described_class) do |instance|
      expect(instance).to receive(:ensure_batched_background_migration_is_finished).with(
        job_class_name: job_class_name,
        table_name: 'gitlab_partitions_dynamic.ci_pipelines_100',
        column_name: :id,
        job_arguments: [],
        finalize: true
      ).once.and_call_original

      expect(instance).to receive(:ensure_batched_background_migration_is_finished).with(
        job_class_name: job_class_name,
        table_name: 'gitlab_partitions_dynamic.ci_pipelines_101',
        column_name: :id,
        job_arguments: [],
        finalize: true
      ).once.and_call_original

      expect(instance).not_to receive(:ensure_batched_background_migration_is_finished).with(
        job_class_name: job_class_name,
        table_name: 'gitlab_partitions_dynamic.ci_pipelines_102',
        column_name: :id,
        job_arguments: [],
        finalize: true
      )
    end

    expect { migrate! }
      .to change { batched_migration_100.reload.status }.to(6) # Finalized status
      .and change { batched_migration_101.reload.status }.to(6)
  end
end
