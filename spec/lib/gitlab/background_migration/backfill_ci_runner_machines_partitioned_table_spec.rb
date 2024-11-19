# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillCiRunnerMachinesPartitionedTable,
  feature_category: :fleet_visibility,
  schema: 20241107064635,
  migration: :gitlab_ci do
  let(:connection) { Ci::ApplicationRecord.connection }

  describe '#perform' do
    let(:runners) { table(:ci_runners) }
    let(:runner_managers) { table(:ci_runner_machines) }
    let(:partitioned_runner_managers) { table(:ci_runner_machines_687967fa8a) }
    let(:args) do
      min, max = runner_managers.pick('MIN(id)', 'MAX(id)')

      {
        start_id: min,
        end_id: max,
        batch_table: 'ci_runner_machines',
        batch_column: 'id',
        sub_batch_size: 100,
        pause_ms: 0,
        job_arguments: ['ci_runner_machines_687967fa8a'],
        connection: connection
      }
    end

    before do
      # Don't sync records to partitioned table
      connection.execute <<~SQL
        DROP TRIGGER table_sync_trigger_61879721b5 ON ci_runners;
        DROP TRIGGER table_sync_trigger_bc3e7b56bd ON ci_runner_machines;
      SQL

      create_runner_and_runner_manager(runner_type: 1, system_xid: 'system1')
      create_runner_and_runner_manager(runner_type: 2, sharding_key_id: 89, system_xid: 'system2')
      create_runner_and_runner_manager(runner_type: 2, sharding_key_id: nil, system_xid: 'system3')
      create_runner_and_runner_manager(runner_type: 3, sharding_key_id: 10, system_xid: 'system2')
      create_runner_and_runner_manager(runner_type: 3, sharding_key_id: nil, system_xid: 'system1')
      create_runner_and_runner_manager(runner_type: 3, sharding_key_id: 100, system_xid: 'system3')

    ensure
      connection.execute <<~SQL
        CREATE TRIGGER table_sync_trigger_bc3e7b56bd
        AFTER INSERT OR DELETE OR UPDATE ON ci_runner_machines
        FOR EACH ROW
        EXECUTE FUNCTION table_sync_function_686d6c7993 ();

        CREATE TRIGGER table_sync_trigger_61879721b5
        AFTER INSERT OR DELETE OR UPDATE ON ci_runners
        FOR EACH ROW
        EXECUTE FUNCTION table_sync_function_686d6c7993 ();
      SQL
    end

    subject(:perform_migration) { described_class.new(**args).perform }

    it 'backfills with valid runner managers', :aggregate_failures do
      expect_next_instance_of(Gitlab::Database::PartitioningMigrationHelpers::BulkCopy) do |bulk_copy|
        expect(bulk_copy).to receive(:copy_relation).and_wrap_original do |original, relation|
          expect(relation).to be_a(ActiveRecord::Relation)
          expect(relation.to_sql).to include <<~SQL.squish
            "ci_runner_machines"."id" BETWEEN #{args[:start_id]} AND #{args[:end_id]}
          SQL
          expect(relation.to_sql).to include <<~SQL.squish
            ("ci_runner_machines"."runner_type" = 1 OR "ci_runner_machines"."sharding_key_id" IS NOT NULL)
          SQL

          original.call(relation)
        end
      end

      perform_migration

      expect(partitioned_runner_managers.count).to eq(4)
    end
  end

  private

  def create_runner_and_runner_manager(**attrs)
    runner = runners.create!(**attrs.except(:system_xid))
    runner_managers.create!(runner_id: runner.id, **attrs)
  end
end
