# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillPartitionIdCiDailyBuildGroupReportResult,
  :suppress_partitioning_routing_analyzer,
  feature_category: :continuous_integration do
  let(:ci_pipelines_table) { table(:ci_pipelines, primary_key: :id, database: :ci) }
  let(:ci_daily_build_group_report_results_table) { table(:ci_daily_build_group_report_results, database: :ci) }
  let!(:pipeline_1) { ci_pipelines_table.create!(id: 1, partition_id: 100, project_id: 1) }
  let!(:pipeline_2) { ci_pipelines_table.create!(id: 2, partition_id: 101, project_id: 1) }
  let!(:pipeline_3) { ci_pipelines_table.create!(id: 3, partition_id: 100, project_id: 1) }
  let!(:ci_daily_build_group_report_results_100) do
    ci_daily_build_group_report_results_table.create!(
      date: 1.day.ago,
      project_id: 1,
      ref_path: 'master',
      group_name: 'rspec',
      data: { 'coverage' => 77.0 },
      default_branch: true,
      last_pipeline_id: pipeline_1.id,
      partition_id: pipeline_1.partition_id
    )
  end

  let!(:ci_daily_build_group_report_results_101) do
    ci_daily_build_group_report_results_table.create!(
      date: Time.current,
      project_id: 1,
      ref_path: 'master',
      group_name: 'rspec',
      data: { 'coverage' => 77.0 },
      default_branch: true,
      last_pipeline_id: pipeline_2.id,
      partition_id: pipeline_2.partition_id
    )
  end

  let!(:invalid_ci_daily_build_group_report_results) do
    ci_daily_build_group_report_results_table.create!(
      date: 1.day.from_now,
      project_id: 1,
      ref_path: 'master',
      group_name: 'rspec',
      data: { 'coverage' => 77.0 },
      default_branch: true,
      last_pipeline_id: pipeline_3.id,
      partition_id: pipeline_3.partition_id
    )
  end

  let(:migration_attrs) do
    {
      start_id: ci_daily_build_group_report_results_table.minimum(:id),
      end_id: ci_daily_build_group_report_results_table.maximum(:id),
      batch_table: :ci_daily_build_group_report_results,
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
    context 'when second partition does not exist' do
      it 'does not execute the migration' do
        expect { migration.perform }
          .not_to change { invalid_ci_daily_build_group_report_results.reload.partition_id }
      end
    end

    context 'when second partition exists' do
      before do
        pipeline_3.update!(partition_id: 101)
      end

      it 'fixes invalid records in the wrong the partition' do
        expect { migration.perform }
          .to not_change { ci_daily_build_group_report_results_100.reload.partition_id }
          .and not_change { ci_daily_build_group_report_results_101.reload.partition_id }
          .and change { invalid_ci_daily_build_group_report_results.reload.partition_id }
          .from(100)
          .to(101)
      end
    end
  end
end
