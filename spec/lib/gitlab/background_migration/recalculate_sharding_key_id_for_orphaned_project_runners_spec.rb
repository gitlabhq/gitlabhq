# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::RecalculateShardingKeyIdForOrphanedProjectRunners, feature_category: :runner, migration: :gitlab_ci do
  let(:connection) { Ci::ApplicationRecord.connection }
  let(:runners) { table(:ci_runners, database: :ci, primary_key: :id) }
  let(:runner_projects) { table(:ci_runner_projects, database: :ci, primary_key: :id) }
  let!(:project_runner1) { runners.create!(id: 1, runner_type: 3, sharding_key_id: 10) }
  let!(:project_runner2) { runners.create!(id: 2, runner_type: 3, sharding_key_id: 10) }
  let!(:project_runner3) { runners.create!(id: 3, runner_type: 3, sharding_key_id: 11) }
  let!(:group_runner1) { runners.create!(id: 4, runner_type: 2, sharding_key_id: 10) }

  before do
    runner_projects.create!(id: 3, project_id: 11, runner_id: project_runner2.id)
    runner_projects.create!(id: 4, project_id: project_runner3.sharding_key_id, runner_id: project_runner3.id)
  end

  describe '#perform' do
    subject(:migration) do
      described_class.new(
        start_id: runners.minimum(:id),
        end_id: runners.maximum(:id),
        batch_table: :ci_runners,
        batch_column: :id,
        sub_batch_size: 2,
        pause_ms: 0,
        connection: connection
      )
    end

    it 'updates from ci_runners where sharding_key_id points to non-existing project', :aggregate_failures do
      expect { migration.perform }
        # Orphaned runner without fallback owner is deleted
        .to change { runners.find_by_id(project_runner1.id) }.to(nil)
        # Orphaned runner will take the fallback owner
        .and change { project_runner2.reload.sharding_key_id }.from(10).to(11)
        # Owned project runner is not affected
        .and not_change { project_runner3.reload.sharding_key_id }.from(11)
        # Group runner with same numeric ID is not affected
        .and not_change { group_runner1.reload.sharding_key_id }.from(10)
    end
  end
end
