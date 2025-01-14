# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::RecalculateShardingKeyIdForOrphanedProjectRunnerTaggings, feature_category: :runner do
  let(:connection) { Ci::ApplicationRecord.connection }
  let(:runners) { table(:ci_runners, database: :ci, primary_key: :id) }
  let(:runner_taggings) { table(:ci_runner_taggings, database: :ci, primary_key: :id) }
  let(:tags) { table(:tags, database: :ci, primary_key: :id) }
  let(:runner_projects) { table(:ci_runner_projects, database: :ci, primary_key: :id) }
  let!(:project_runner1) { runners.create!(id: 1, runner_type: 3, sharding_key_id: 10) }
  let!(:project_runner2) { runners.create!(id: 2, runner_type: 3, sharding_key_id: 10) }
  let!(:project_runner3) { runners.create!(id: 3, runner_type: 3, sharding_key_id: 11) }
  let!(:tag1) { tags.create!(id: 1, name: 'tag1') }
  let!(:tag2) { tags.create!(id: 2, name: 'tag2') }
  let!(:project_runner1_taggings) do
    common_attrs = { runner_id: project_runner1.id, runner_type: 3, sharding_key_id: 10 }

    [
      runner_taggings.create!(tag_id: tag1.id, **common_attrs),
      runner_taggings.create!(tag_id: tag2.id, **common_attrs)
    ]
  end

  let!(:project_runner2_tagging) do
    runner_taggings.create!(runner_id: project_runner2.id, tag_id: tag1.id, runner_type: 3, sharding_key_id: 10)
  end

  let!(:project_runner3_tagging) do
    runner_taggings.create!(runner_id: project_runner3.id, tag_id: tag2.id, runner_type: 3, sharding_key_id: 11)
  end

  let!(:group_runner1) { runners.create!(id: 4, runner_type: 2, sharding_key_id: 10) }
  let!(:group_runner1_tagging) do
    runner_taggings.create!(runner_id: group_runner1.id, tag_id: tag2.id, runner_type: 2, sharding_key_id: 10)
  end

  before do
    runner_projects.create!(id: 3, project_id: 11, runner_id: project_runner2.id)
    runner_projects.create!(id: 4, project_id: project_runner3.sharding_key_id, runner_id: project_runner3.id)
  end

  describe '#perform' do
    subject(:migration) do
      described_class.new(
        start_id: runner_taggings.minimum(:runner_id),
        end_id: runner_taggings.maximum(:runner_id),
        batch_table: :ci_runner_taggings,
        batch_column: :runner_id,
        sub_batch_size: 2,
        pause_ms: 0,
        connection: connection
      )
    end

    it 'updates from ci_runner_taggings where sharding_key_id points to non-existing project', :aggregate_failures do
      expect { migration.perform }
        # Leave it for RecalculateShardingKeyIdForOrphanedProjectRunners to cascade the deletion from the runners
        .to not_change { runner_taggings.find_by_id(project_runner1_taggings.first.id) }
        .and not_change { runner_taggings.find_by_id(project_runner1_taggings.second.id) }
        # Orphaned runner manager will take the fallback owner
        .and change { project_runner2_tagging.reload.sharding_key_id }.from(10).to(11)
        # Owned project runner manager is not affected
        .and not_change { project_runner3_tagging.reload.sharding_key_id }.from(11)
        # Group runner manager with same numeric ID is not affected
        .and not_change { group_runner1_tagging.reload.sharding_key_id }.from(10)
    end
  end
end
