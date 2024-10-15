# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillRunnerTypeAndShardingKeyIdOnCiRunnerManagers,
  schema: 20241003110148, migration: :gitlab_ci, feature_category: :runner do
  let(:connection) { Ci::ApplicationRecord.connection }

  describe '#perform' do
    let(:runner_managers) { table(:ci_runner_machines) }
    let(:runners) { table(:ci_runners) }
    let(:args) do
      min, max = runner_managers.pick('MIN(id)', 'MAX(id)')

      {
        start_id: min,
        end_id: max,
        batch_table: 'ci_runner_machines',
        batch_column: 'id',
        sub_batch_size: 100,
        pause_ms: 0,
        connection: connection
      }
    end

    let!(:instance_runner) { runners.create!(runner_type: 1) }
    let!(:group_runner) { runners.create!(runner_type: 2, sharding_key_id: 89) }
    let!(:project_runner1) { runners.create!(runner_type: 3, sharding_key_id: 10) }
    let!(:project_runner2) { runners.create!(runner_type: 3, sharding_key_id: 100) }

    let!(:runner_manager1) { create_runner_manager(instance_runner, system_xid: 'a') }
    let!(:runner_manager2_1) { create_runner_manager(group_runner, system_xid: 'a') }
    let!(:runner_manager2_2) { create_runner_manager(group_runner, system_xid: 'b') }
    let!(:runner_manager3) { create_runner_manager(project_runner1, system_xid: 'a') }
    let!(:runner_manager4) { create_runner_manager(project_runner2, system_xid: 'b') }

    subject(:perform_migration) { described_class.new(**args).perform }

    it 'backfills runner_type and sharding_key_id', :aggregate_failures do
      expect { perform_migration }
        .to change { runner_manager2_1.reload.sharding_key_id }.from(nil).to(group_runner.sharding_key_id)
        .and change { runner_manager2_2.reload.sharding_key_id }.from(nil).to(group_runner.sharding_key_id)
        .and change { runner_manager3.reload.sharding_key_id }.from(nil).to(project_runner1.sharding_key_id)
        .and change { runner_manager4.reload.sharding_key_id }.from(nil).to(project_runner2.sharding_key_id)
        .and not_change { runner_manager2_1.reload.runner_type }.from(group_runner.runner_type)
        .and not_change { runner_manager2_2.reload.runner_type }.from(group_runner.runner_type)
        .and not_change { runner_manager3.reload.runner_type }.from(project_runner1.runner_type)
        .and not_change { runner_manager4.reload.runner_type }.from(project_runner2.runner_type)

      expect(runner_manager1.sharding_key_id).to be_nil
    end

    private

    def create_runner_manager(runner, **attrs)
      runner_managers.create!(runner_id: runner.id, runner_type: runner.runner_type, **attrs)
    end
  end
end
