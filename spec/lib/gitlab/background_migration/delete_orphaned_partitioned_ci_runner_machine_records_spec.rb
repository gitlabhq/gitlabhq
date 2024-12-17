# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::DeleteOrphanedPartitionedCiRunnerMachineRecords,
  feature_category: :fleet_visibility, migration: :gitlab_ci do
  let(:connection) { Ci::ApplicationRecord.connection }
  let(:runners) { table(:ci_runners_e59bb2812d, database: :ci, primary_key: :id) }
  let(:runner_managers) { table(:ci_runner_machines_687967fa8a, database: :ci, primary_key: :id) }
  let(:orphaned_group_runner_manager) { runner_managers.find(3) }
  let(:orphaned_project_runner_manager) { runner_managers.find(5) }

  before do
    # Allow creating legacy runner managers (created when FK was not present) that are not connected to a runner
    connection.transaction do
      connection.execute(<<~SQL)
        ALTER TABLE group_type_ci_runner_machines_687967fa8a DISABLE TRIGGER ALL;
        ALTER TABLE project_type_ci_runner_machines_687967fa8a DISABLE TRIGGER ALL;
      SQL

      create_runner_and_runner_manager(id: 1, runner_type: 1, system_xid: 'system1')
      create_runner_and_runner_manager(id: 2, runner_type: 2, sharding_key_id: 89, system_xid: 'system2')
      runner_managers.create!(
        id: 3, runner_id: non_existing_record_id, runner_type: 2, sharding_key_id: 100, system_xid: 'system2'
      )
      create_runner_and_runner_manager(id: 4, runner_type: 3, sharding_key_id: 10, system_xid: 'system2')
      runner_managers.create!(
        id: 5, runner_id: non_existing_record_id, runner_type: 3, sharding_key_id: 100, system_xid: 'system3'
      )

      connection.execute(<<~SQL)
        ALTER TABLE group_type_ci_runner_machines_687967fa8a ENABLE TRIGGER ALL;
        ALTER TABLE project_type_ci_runner_machines_687967fa8a ENABLE TRIGGER ALL;
      SQL
    end
  end

  describe '#perform' do
    subject(:migration) do
      described_class.new(
        start_id: runner_managers.minimum(:runner_id),
        end_id: runner_managers.maximum(:runner_id),
        batch_table: :ci_runner_machines_687967fa8a,
        batch_column: :runner_id,
        sub_batch_size: 2,
        pause_ms: 0,
        connection: connection
      )
    end

    it 'deletes from ci_runner_machines_687967fa8a where runner_id has no related', :aggregate_failures do
      instance_runner_manager = runner_managers.where(runner_type: 1).first

      expect { migration.perform }.to change { runner_managers.count }.from(5).to(3)

      expect(instance_runner_manager.reload).to be_persisted
      expect { orphaned_group_runner_manager.reload }.to raise_error(ActiveRecord::RecordNotFound)
      expect { orphaned_project_runner_manager.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  private

  def create_runner_and_runner_manager(**attrs)
    runner = runners.create!(**attrs.except(:system_xid))
    runner_managers.create!(runner_id: runner.id, **attrs)
  end
end
