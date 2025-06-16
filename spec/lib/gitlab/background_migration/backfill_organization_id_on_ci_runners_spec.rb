# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillOrganizationIdOnCiRunners,
  migration: :gitlab_ci, feature_category: :fleet_visibility do
  let(:connection) { Ci::ApplicationRecord.connection }

  describe '#perform' do
    let(:runners) { table(:ci_runners, primary_key: :id) }
    let(:args) do
      min, max = runners.pick('MIN(id)', 'MAX(id)')

      {
        start_id: min,
        end_id: max,
        batch_table: 'ci_runners',
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

    subject(:perform_migration) { described_class.new(**args).perform }

    it 'backfills organization_id', :aggregate_failures do
      expect { perform_migration }
        .to change { group_runner.reload.organization_id }.from(nil).to(described_class::DEFAULT_ORG_ID)
        .and change { project_runner1.reload.organization_id }.from(nil).to(described_class::DEFAULT_ORG_ID)
        .and change { project_runner2.reload.organization_id }.from(nil).to(described_class::DEFAULT_ORG_ID)

      expect(instance_runner.organization_id).to be_nil
    end
  end
end
