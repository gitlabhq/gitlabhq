# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillOrganizationIdOnCiRunnerTaggings,
  migration: :gitlab_ci, feature_category: :runner do
  let(:connection) { Ci::ApplicationRecord.connection }

  describe '#perform' do
    let(:runner_taggings) { table(:ci_runner_taggings, primary_key: :id) }
    let(:tags) { table(:tags, primary_key: :id) }
    let(:runners) { table(:ci_runners, primary_key: :id) }
    let(:args) do
      min, max = runner_taggings.pick('MIN(id)', 'MAX(id)')

      {
        start_id: min,
        end_id: max,
        batch_table: 'ci_runner_taggings',
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

    let!(:tag) { tags.create!(name: 'foo') }
    let!(:instance_runner_tagging) { create_runner_tagging(instance_runner) }
    let!(:group_runner_tagging) { create_runner_tagging(group_runner) }
    let!(:project_runner1_tagging) { create_runner_tagging(project_runner1) }
    let!(:project_runner2_tagging) { create_runner_tagging(project_runner2) }

    subject(:perform_migration) { described_class.new(**args).perform }

    it 'backfills organization_id', :aggregate_failures do
      expect { perform_migration }
        .to change { group_runner_tagging.reload.organization_id }.from(nil).to(described_class::DEFAULT_ORG_ID)
        .and change { project_runner1_tagging.reload.organization_id }.from(nil).to(described_class::DEFAULT_ORG_ID)
        .and change { project_runner2_tagging.reload.organization_id }.from(nil).to(described_class::DEFAULT_ORG_ID)

      expect(instance_runner_tagging.organization_id).to be_nil
    end

    private

    def create_runner_tagging(runner, **attrs)
      runner_taggings.create!(
        runner_id: runner.id, runner_type: runner.runner_type, sharding_key_id: runner.sharding_key_id, tag_id: tag.id,
        **attrs
      )
    end
  end
end
