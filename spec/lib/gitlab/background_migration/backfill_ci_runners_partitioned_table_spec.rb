# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillCiRunnersPartitionedTable, schema: 20250113151324,
  feature_category: :runner, migration: :gitlab_ci do
  let(:connection) { Ci::ApplicationRecord.connection }

  describe '#perform' do
    let(:runners) { table(:ci_runners, database: :ci) }
    let(:partitioned_runners) { table(:ci_runners_e59bb2812d, database: :ci) }
    let(:args) do
      min, max = runners.pick('MIN(id)', 'MAX(id)')

      {
        start_id: min,
        end_id: max,
        batch_table: 'ci_runners',
        batch_column: 'id',
        sub_batch_size: 100,
        pause_ms: 0,
        job_arguments: ['ci_runners_e59bb2812d'],
        connection: connection
      }
    end

    before do
      connection.transaction do
        connection.execute <<~SQL
          ALTER TABLE ci_runners DISABLE TRIGGER ALL; -- Don't sync records to partitioned table

          INSERT INTO ci_runners(runner_type) VALUES (1);
          INSERT INTO ci_runners(runner_type, sharding_key_id) VALUES (2, 89);
          INSERT INTO ci_runners(runner_type, sharding_key_id) VALUES (2, NULL);
          INSERT INTO ci_runners(runner_type, sharding_key_id) VALUES (3, 10);
          INSERT INTO ci_runners(runner_type, sharding_key_id) VALUES (3, NULL);
          INSERT INTO ci_runners(runner_type, sharding_key_id) VALUES (3, 100);

          ALTER TABLE ci_runners ENABLE TRIGGER ALL;
        SQL
      end
    end

    subject(:perform_migration) { described_class.new(**args).perform }

    it 'backfills with valid runners', :aggregate_failures do
      expect_next_instance_of(Gitlab::Database::PartitioningMigrationHelpers::BulkCopy) do |bulk_copy|
        expect(bulk_copy).to receive(:copy_relation).and_wrap_original do |original, relation|
          expect(relation).to be_a(ActiveRecord::Relation)
          expect(relation.to_sql).to include <<~SQL.squish
            "ci_runners"."id" BETWEEN #{args[:start_id]} AND #{args[:end_id]}
          SQL
          expect(relation.to_sql).to include <<~SQL.squish
            ("ci_runners"."runner_type" = 1 OR "ci_runners"."sharding_key_id" IS NOT NULL)
          SQL

          original.call(relation)
        end
      end

      perform_migration

      expect(partitioned_runners.count).to eq(4)
    end
  end
end
