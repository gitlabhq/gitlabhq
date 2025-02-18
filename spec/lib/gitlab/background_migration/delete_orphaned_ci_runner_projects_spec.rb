# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::DeleteOrphanedCiRunnerProjects, feature_category: :runner,
  migration: :gitlab_ci, schema: 20250113153424 do
  let(:connection) { Ci::ApplicationRecord.connection }
  let(:runners) { table(:ci_runners, database: :ci, primary_key: :id) }
  let(:runner_projects) { table(:ci_runner_projects, database: :ci, primary_key: :id) }
  let!(:group_runner1) { runners.create!(id: 1, runner_type: 2, sharding_key_id: 1) }
  let!(:project_runner1) { runners.create!(id: 2, runner_type: 3, sharding_key_id: 10) }
  let!(:project_runner2) { runners.create!(id: 3, runner_type: 3, sharding_key_id: 10) }
  let!(:project_runner3) { runners.create!(id: 4, runner_type: 3, sharding_key_id: 10) }
  let!(:runner1_project) { runner_projects.create!(id: 1, project_id: 10, runner_id: project_runner1.id) }
  let!(:runner2_project1) { runner_projects.create!(id: 2, project_id: 10, runner_id: project_runner2.id) }
  let!(:runner2_project2) { runner_projects.create!(id: 3, project_id: 11, runner_id: project_runner2.id) }
  let!(:runner3_project) { runner_projects.create!(id: 4, project_id: 11, runner_id: project_runner3.id) }
  let(:orphaned_runner_project) { runner_projects.find(2) }

  before do
    connection.transaction do
      connection.execute(<<~SQL)
        ALTER TABLE ci_runners DISABLE TRIGGER ALL;
      SQL

      project_runner2.delete

      connection.execute(<<~SQL)
        ALTER TABLE ci_runners ENABLE TRIGGER ALL;
      SQL
    end
  end

  describe '#perform' do
    subject(:migration) do
      described_class.new(
        start_id: runner_projects.minimum(:runner_id),
        end_id: runner_projects.maximum(:runner_id),
        batch_table: :ci_runner_projects,
        batch_column: :runner_id,
        sub_batch_size: 2,
        pause_ms: 0,
        connection: connection
      )
    end

    it 'deletes from ci_runner_projects where runner_id points to non-existing runner', :aggregate_failures do
      expect(runner_projects.find(2)).to be_persisted

      expect { migration.perform }.to change { runner_projects.count }.from(4).to(2)

      expect(runner1_project.reload).to be_persisted
      expect(runner3_project.reload).to be_persisted
      expect { runner2_project1.reload }.to raise_error(ActiveRecord::RecordNotFound)
      expect { runner2_project2.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
