# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::FixBadShardingKeyIdOnProjectCiRunners, migration: :gitlab_ci,
  feature_category: :runner_core do
  include Database::TableSchemaHelpers

  let(:connection) { Ci::ApplicationRecord.connection }

  describe '#perform' do
    let(:runners) { table(:ci_runners, primary_key: :id) }
    let(:runner_projects) { table(:ci_runner_projects, primary_key: :id) }
    let(:instance_runner) { runners.create!(runner_type: 1) }
    let(:project_id) { 1000 }
    let(:project2_id) { 1001 }
    let(:orphaned_project_runner) { create_project_runner(project_ids: [non_existing_record_id, project_id]) }
    let(:orphaned_project_runner2) { create_project_runner(project_ids: [non_existing_record_id]) }
    let(:project_runner) { create_project_runner(project_ids: [project_id, non_existing_record_id]) }
    let(:project2_runner) { create_project_runner(project_ids: [project2_id, project_id]) }
    let(:args) do
      min, max = runners.pick('MIN(id)', 'MAX(id)')

      {
        start_id: min,
        end_id: max,
        batch_table: 'ci_runners',
        batch_column: 'id',
        sub_batch_size: 2,
        pause_ms: 0,
        connection: connection
      }
    end

    subject(:perform_migration) { described_class.new(**args).perform }

    it 'backfills sharding_key_id of orphaned runners', :aggregate_failures do
      expect { perform_migration }
        .to change { orphaned_project_runner.reload.sharding_key_id }.from(non_existing_record_id).to(project_id)
        .and not_change { orphaned_project_runner2.reload.sharding_key_id }.from(non_existing_record_id)
        .and not_change { instance_runner.reload.sharding_key_id }.from(nil)
        .and not_change { project_runner.reload.sharding_key_id }.from(project_id)
        .and not_change { project2_runner.reload.sharding_key_id }.from(project2_id)
    end

    def create_project_runner(project_ids:)
      project_ids = Array.wrap(project_ids)

      runners.create!(runner_type: 3, sharding_key_id: project_ids.first).tap do |runner|
        project_ids.excluding(non_existing_record_id).each do |project_id|
          runner_projects.create!(runner_id: runner.id, project_id: project_id)
        end
      end
    end
  end
end
