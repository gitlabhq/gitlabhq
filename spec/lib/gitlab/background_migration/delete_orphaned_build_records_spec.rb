# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::DeleteOrphanedBuildRecords, feature_category: :continuous_integration, migration: :gitlab_ci do
  let(:pipelines_table) { table(:p_ci_pipelines, database: :ci, primary_key: :id) }
  let(:builds_table) { table(:p_ci_builds, database: :ci, primary_key: :id) }

  let!(:regular_pipeline) { pipelines_table.create!(project_id: 600, partition_id: 100) }
  let!(:deleted_pipeline) { pipelines_table.create!(project_id: 600, partition_id: 100) }
  let!(:other_pipeline) { pipelines_table.create!(project_id: 600, partition_id: 100) }

  let!(:regular_build) do
    builds_table.create!(partition_id: 100, project_id: 600, commit_id: regular_pipeline.id)
  end

  let!(:orphaned_build) do
    builds_table.create!(partition_id: 100, project_id: 600, commit_id: deleted_pipeline.id)
  end

  let(:connection) { Ci::ApplicationRecord.connection }

  describe '#perform' do
    subject(:migration) do
      described_class.new(
        start_id: builds_table.minimum(:commit_id),
        end_id: builds_table.maximum(:commit_id),
        batch_table: :p_ci_builds,
        batch_column: :commit_id,
        sub_batch_size: 100,
        pause_ms: 0,
        connection: connection
      )
    end

    it 'deletes from p_ci_builds where commit_id has no related record at p_ci_pipelines.id', :aggregate_failures do
      without_referential_integrity do
        expect { deleted_pipeline.delete }.to not_change { builds_table.count }

        expect { migration.perform }.to change { builds_table.count }.from(2).to(1)

        expect(regular_build.reload).to be_persisted
        expect { orphaned_build.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    def without_referential_integrity
      connection.transaction do
        connection.execute('ALTER TABLE ci_pipelines DISABLE TRIGGER ALL;')

        yield

        connection.execute('ALTER TABLE ci_pipelines ENABLE TRIGGER ALL;')
      end
    end
  end
end
