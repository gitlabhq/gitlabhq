# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillPartitionedProjectDailyStatistics,
  feature_category: :source_code_management do
  let(:connection) { ApplicationRecord.connection }
  let(:organization) { table(:organizations).create!(name: 'organization', path: 'organization') }
  let(:namespace) { table(:namespaces).create!(name: 'namespace', path: 'namespace', organization_id: organization.id) }
  let(:project) do
    table(:projects).create!(
      namespace_id: namespace.id,
      project_namespace_id: namespace.id,
      organization_id: organization.id
    )
  end

  describe '#perform' do
    let(:project_daily_statistics) { table(:project_daily_statistics) }
    let(:partitioned_table) { table(:project_daily_statistics_b8088ecbd2) }

    let(:in_range_date) { 2.months.ago.to_date }
    let(:outdated_date) { 4.months.ago.to_date }

    let(:args) do
      min, max = project_daily_statistics.pick('MIN(id)', 'MAX(id)')

      {
        start_id: min,
        end_id: max,
        batch_table: 'project_daily_statistics',
        batch_column: 'id',
        sub_batch_size: 100,
        pause_ms: 0,
        job_arguments: ['project_daily_statistics_b8088ecbd2'],
        connection: connection
      }
    end

    before do
      # Drop default partition if it exists to allow creating specific month partitions
      connection.execute(<<~SQL)
        DROP TABLE IF EXISTS gitlab_partitions_dynamic.project_daily_statistics_b8088ecbd2_000000;
      SQL

      # Create partitions for both outdated and in-range data
      [outdated_date, in_range_date].each do |date|
        month = date.beginning_of_month
        partition_name = "project_daily_statistics_b8088ecbd2_#{month.strftime('%Y%m')}"

        connection.execute(<<~SQL)
          CREATE TABLE IF NOT EXISTS gitlab_partitions_dynamic.#{partition_name}
          PARTITION OF project_daily_statistics_b8088ecbd2
          FOR VALUES FROM ('#{month}') TO ('#{month + 1.month}');
        SQL
      end

      connection.execute(<<~SQL)
        ALTER TABLE project_daily_statistics DISABLE TRIGGER ALL; -- Don't sync records to partitioned table

        INSERT INTO project_daily_statistics (project_id, fetch_count, date)
        VALUES
          (#{project.id}, 10, '#{outdated_date}'),
          (#{project.id}, 20, '#{in_range_date}'),
          (#{project.id}, 30, '#{in_range_date + 1.day}');
      SQL
    end

    after do
      # Drop the specific month partitions we created
      [outdated_date, in_range_date].each do |date|
        month = date.beginning_of_month
        partition_name = "project_daily_statistics_b8088ecbd2_#{month.strftime('%Y%m')}"

        connection.execute(<<~SQL)
          DROP TABLE IF EXISTS gitlab_partitions_dynamic.#{partition_name};
        SQL
      end

      # Recreate the default partition
      connection.execute(<<~SQL)
        CREATE TABLE IF NOT EXISTS gitlab_partitions_dynamic.project_daily_statistics_b8088ecbd2_000000
        PARTITION OF project_daily_statistics_b8088ecbd2
        DEFAULT;
      SQL

      # Re-enable triggers
      connection.execute(<<~SQL)
        ALTER TABLE project_daily_statistics ENABLE TRIGGER ALL;
      SQL
    end

    subject(:perform_migration) { described_class.new(**args).perform }

    it 'only backfills records within the 3-month retention window', :aggregate_failures do
      expected_filter_date = 3.months.ago.beginning_of_month.to_date

      expect_next_instance_of(Gitlab::Database::PartitioningMigrationHelpers::BulkCopy) do |bulk_copy|
        expect(bulk_copy).to receive(:copy_relation).and_wrap_original do |original, relation|
          expect(relation).to be_a(ActiveRecord::Relation)

          # Verify the SQL includes our date filter
          expect(relation.to_sql).to include <<~SQL.squish
            "project_daily_statistics"."date" >= '#{expected_filter_date}'
          SQL

          original.call(relation)
        end
      end

      perform_migration

      # Only the 2 in-range records should be copied (outdated one should be skipped)
      expect(partitioned_table.count).to eq(2)
      expect(partitioned_table.pluck(:date)).to contain_exactly(in_range_date, in_range_date + 1.day)
    end
  end
end
