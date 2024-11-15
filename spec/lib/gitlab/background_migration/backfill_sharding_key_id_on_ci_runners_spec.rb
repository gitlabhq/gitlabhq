# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillShardingKeyIdOnCiRunners, schema: 20240923132401,
  migration: :gitlab_ci, feature_category: :runner do
  include Database::TableSchemaHelpers

  let(:connection) { Ci::ApplicationRecord.connection }

  describe '#perform' do
    let(:runners) { table(:ci_runners) }
    let(:runner_projects) { table(:ci_runner_projects) }
    let(:runner_namespaces) { table(:ci_runner_namespaces) }

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

    let(:group_id) { 100 }
    let(:other_group_id) { 101 }
    let(:project_id) { 1000 }
    let(:other_project_id) { 1001 }
    let(:orphaned_project_runner) { create_project_runner(project_ids: []) }

    subject(:perform_migration) { described_class.new(**args).perform }

    before do
      runners.create!(runner_type: 1)

      orphaned_project_runner
      create_project_runner(project_ids: project_id)
      create_project_runner(project_ids: other_project_id)

      create_group_runner(group_id: group_id)
      create_group_runner(group_id: other_group_id)
    end

    it 'backfills sharding_key_id', :aggregate_failures do
      expect { perform_migration }.not_to change { orphaned_project_runner.sharding_key_id }

      runners.where(runner_type: 1).find_each do |runner|
        expect(runner.sharding_key_id).to be_nil
      end

      runner_namespaces.find_each do |runner_namespace|
        expect(runners.find(runner_namespace.runner_id).sharding_key_id).to eq(runner_namespace.namespace_id)
      end

      runner_projects.find_each do |runner_project|
        expect(runners.find(runner_project.runner_id).sharding_key_id).to eq(runner_project.project_id)
      end
    end

    context 'when a project runner is shared with other projects' do
      let(:runner_project_ids) { [other_project_id, project_id] }

      it 'backfills sharding_key_id with the id of the owner project' do
        shared_project_runner = create_project_runner(project_ids: runner_project_ids)

        expect do
          perform_migration
        end.to change { shared_project_runner.reload.sharding_key_id }.from(nil).to(other_project_id)
      end

      context 'when the project has a different owner project' do
        let(:runner_project_ids) { [project_id, other_project_id] }

        it 'backfills sharding_key_id with the id of the owner project' do
          shared_project_runner = create_project_runner(project_ids: runner_project_ids)

          expect do
            perform_migration
          end.to change { shared_project_runner.reload.sharding_key_id }.from(nil).to(project_id)
        end
      end
    end

    def create_group_runner(group_id:)
      runners.create!(runner_type: 2, sharding_key_id: nil).tap do |runner|
        runner_namespaces.create!(runner_id: runner.id, namespace_id: group_id)
      end
    end

    def create_project_runner(project_ids:)
      project_ids = Array.wrap(project_ids)

      runners.create!(runner_type: 3, sharding_key_id: nil).tap do |runner|
        project_ids.each do |project_id|
          runner_projects.create!(runner_id: runner.id, project_id: project_id)
        end
      end
    end
  end
end
