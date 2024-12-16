# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillCiRunnerMachinesPartitionedTable,
  feature_category: :fleet_visibility, migration: :gitlab_ci do
  let(:connection) { Ci::ApplicationRecord.connection }

  describe '#perform' do
    let(:runners) { table(:ci_runners, database: :ci) }
    let(:runner_managers) { table(:ci_runner_machines, database: :ci) }
    let(:partitioned_runner_managers) { table(:ci_runner_machines_687967fa8a, database: :ci) }
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
      create_runner_and_runner_manager(runner_type: 1, system_xid: 'system1')
      create_runner_and_runner_manager(runner_type: 2, sharding_key_id: 89, system_xid: 'system2')
      create_runner_and_runner_manager(runner_type: 3, sharding_key_id: 10, system_xid: 'system2')
      create_runner_and_runner_manager(runner_type: 3, sharding_key_id: 100, system_xid: 'system3')

      # Don't sync records to partitioned table
      connection.transaction do
        connection.execute(<<~SQL)
          ALTER TABLE ci_runners DISABLE TRIGGER ALL;
          ALTER TABLE ci_runner_machines DISABLE TRIGGER ALL;
        SQL

        create_runner_and_runner_manager(runner_type: 3, sharding_key_id: nil, system_xid: 'system1')
        create_runner_and_runner_manager(runner_type: 2, sharding_key_id: nil, system_xid: 'system3')

        connection.execute(<<~SQL)
          ALTER TABLE ci_runners ENABLE TRIGGER ALL;
          ALTER TABLE ci_runner_machines ENABLE TRIGGER ALL;
        SQL
      end
    end

    subject(:perform_migration) { described_class.new(**args).perform }

    it 'backfills with valid runner managers', :aggregate_failures do
      expect(runner_managers.where(sharding_key_id: nil).count).to eq 3

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
