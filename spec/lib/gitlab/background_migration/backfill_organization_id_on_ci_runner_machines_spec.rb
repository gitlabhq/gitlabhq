# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillOrganizationIdOnCiRunnerMachines,
  migration: :gitlab_ci, feature_category: :fleet_visibility do
  let(:connection) { Ci::ApplicationRecord.connection }

  describe '#perform' do
    let(:runner_managers) { table(:ci_runner_machines, primary_key: :id) }
    let(:runners) { table(:ci_runners, primary_key: :id) }
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

    it 'backfills organization_id', :aggregate_failures do
      expect { perform_migration }
        .to change { runner_manager2_1.reload.organization_id }.from(nil).to(described_class::DEFAULT_ORG_ID)
        .and change { runner_manager2_2.reload.organization_id }.from(nil).to(described_class::DEFAULT_ORG_ID)
        .and change { runner_manager3.reload.organization_id }.from(nil).to(described_class::DEFAULT_ORG_ID)
        .and change { runner_manager4.reload.organization_id }.from(nil).to(described_class::DEFAULT_ORG_ID)

      expect(runner_manager1.organization_id).to be_nil
    end

    private

    def create_runner_manager(runner, **attrs)
      runner_managers.create!(
        runner_id: runner.id, runner_type: runner.runner_type, sharding_key_id: runner.sharding_key_id, **attrs
      )
    end
  end
end
