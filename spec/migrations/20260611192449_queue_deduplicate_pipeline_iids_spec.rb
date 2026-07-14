# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe QueueDeduplicatePipelineIids, migration: :gitlab_ci, feature_category: :continuous_integration do
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
      CREATE TABLE IF NOT EXISTS "gitlab_partitions_dynamic"."ci_pipelines_108"
        PARTITION OF "p_ci_pipelines" FOR VALUES IN (108);
    SQL

    pipelines_table.create!(partition_id: 100, project_id: 1)
    pipelines_table.create!(partition_id: 101, project_id: 2)
    pipelines_table.create!(partition_id: 108, project_id: 3)
  end

  def expect_scheduled(table_name, job_arguments)
    expect(batched_migration).to have_scheduled_batched_migration(
      gitlab_schema: :gitlab_ci,
      table_name: table_name,
      column_name: :id,
      job_arguments: job_arguments,
      batch_size: described_class::BATCH_SIZE,
      sub_batch_size: described_class::SUB_BATCH_SIZE
    )
  end

  def expect_not_scheduled(table_name, job_arguments)
    expect(batched_migration).not_to have_scheduled_batched_migration(
      gitlab_schema: :gitlab_ci,
      table_name: table_name,
      column_name: :id,
      job_arguments: job_arguments
    )
  end

  it 'schedules a batched migration per non-empty partition' do
    reversible_migration do |migration|
      migration.before -> {
        expect(batched_migration).not_to have_scheduled_batched_migration
      }

      migration.after -> {
        expect_scheduled('gitlab_partitions_dynamic.ci_pipelines_100', [[100]])
        expect_scheduled('gitlab_partitions_dynamic.ci_pipelines_101', [[101]])
        expect_scheduled('gitlab_partitions_dynamic.ci_pipelines_108', [[108]])

        # Does not schedule empty partitions
        expect_not_scheduled('gitlab_partitions_dynamic.ci_pipelines_102', [[102]])
      }
    end
  end

  context 'on GitLab.com' do
    before do
      allow(Gitlab).to receive(:com_except_jh?).and_return(true)
    end

    it 'skips partitions newer than the duplicates (partition_id > 107)' do
      reversible_migration do |migration|
        migration.after -> {
          expect_scheduled('gitlab_partitions_dynamic.ci_pipelines_100', [[100]])
          expect_scheduled('gitlab_partitions_dynamic.ci_pipelines_101', [[101]])

          expect_not_scheduled('gitlab_partitions_dynamic.ci_pipelines_108', [[108]])
        }
      end
    end
  end
end
