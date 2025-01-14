# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::RecalculateShardingKeyIdForOrphanedProjectRunnerManagers, feature_category: :runner do
  let(:connection) { Ci::ApplicationRecord.connection }
  let(:runners) { table(:ci_runners, database: :ci, primary_key: :id) }
  let(:runner_machines) { table(:ci_runner_machines, database: :ci, primary_key: :id) }
  let(:runner_projects) { table(:ci_runner_projects, database: :ci, primary_key: :id) }
  let!(:project_runner1) { runners.create!(id: 1, runner_type: 3, sharding_key_id: 10) }
  let!(:project_runner2) { runners.create!(id: 2, runner_type: 3, sharding_key_id: 10) }
  let!(:project_runner3) { runners.create!(id: 3, runner_type: 3, sharding_key_id: 11) }
  let!(:project_runner1_machines) do
    common_attrs = { runner_id: project_runner1.id, runner_type: 3, sharding_key_id: 10 }

    [
      runner_machines.create!(id: 1, system_xid: 'a', **common_attrs),
      runner_machines.create!(id: 2, system_xid: 'b', **common_attrs)
    ]
  end

  let!(:project_runner2_machine) do
    runner_machines.create!(id: 4, runner_id: project_runner2.id, system_xid: 'a', runner_type: 3, sharding_key_id: 10)
  end

  let!(:project_runner3_machine) do
    runner_machines.create!(id: 5, runner_id: project_runner3.id, system_xid: 'a', runner_type: 3, sharding_key_id: 11)
  end

  let!(:group_runner1) { runners.create!(id: 4, runner_type: 2, sharding_key_id: 10) }
  let!(:group_runner1_machine) do
    runner_machines.create!(id: 6, runner_id: group_runner1.id, system_xid: 'a', runner_type: 2, sharding_key_id: 10)
  end

  before do
    runner_projects.create!(id: 3, project_id: 11, runner_id: project_runner2.id)
    runner_projects.create!(id: 4, project_id: project_runner3.sharding_key_id, runner_id: project_runner3.id)
  end

  describe '#perform' do
    subject(:migration) do
      described_class.new(
        start_id: runner_machines.minimum(:runner_id),
        end_id: runner_machines.maximum(:runner_id),
        batch_table: :ci_runner_machines,
        batch_column: :runner_id,
        sub_batch_size: 2,
        pause_ms: 0,
        connection: connection
      )
    end

    it 'updates from ci_runner_machines where sharding_key_id points to non-existing project', :aggregate_failures do
      expect { migration.perform }
        # Leave it for RecalculateShardingKeyIdForOrphanedProjectRunners to cascade the deletion from the runners
        .to not_change { runner_machines.find_by_id(project_runner1_machines.first.id) }
        .and not_change { runner_machines.find_by_id(project_runner1_machines.second.id) }
        # Orphaned runner manager will take the fallback owner
        .and change { project_runner2_machine.reload.sharding_key_id }.from(10).to(11)
        # Owned project runner manager is not affected
        .and not_change { project_runner3_machine.reload.sharding_key_id }.from(11)
        # Group runner manager with same numeric ID is not affected
        .and not_change { group_runner1_machine.reload.sharding_key_id }.from(10)
    end
  end
end
