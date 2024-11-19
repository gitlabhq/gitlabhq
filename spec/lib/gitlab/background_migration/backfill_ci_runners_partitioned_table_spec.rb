# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillCiRunnersPartitionedTable,
  feature_category: :runner,
  schema: 20241023144448,
  migration: :gitlab_ci do
  let(:connection) { Ci::ApplicationRecord.connection }

  describe '#perform' do
    let(:runners) { table(:ci_runners) }
    let(:partitioned_runners) { table(:ci_runners_e59bb2812d) }
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
      # Don't sync records to partitioned table
      connection.execute <<~SQL
        DROP TRIGGER table_sync_trigger_61879721b5 ON ci_runners;
      SQL

      runners.create!(runner_type: 1)
      runners.create!(runner_type: 2, sharding_key_id: 89)
      runners.create!(runner_type: 2, sharding_key_id: nil)
      runners.create!(runner_type: 3, sharding_key_id: 10)
      runners.create!(runner_type: 3, sharding_key_id: nil)
      runners.create!(runner_type: 3, sharding_key_id: 100)

    ensure
      connection.execute <<~SQL
        CREATE TRIGGER table_sync_trigger_61879721b5
        AFTER INSERT OR DELETE OR UPDATE ON ci_runners
        FOR EACH ROW
        EXECUTE FUNCTION table_sync_function_686d6c7993 ();
      SQL
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
