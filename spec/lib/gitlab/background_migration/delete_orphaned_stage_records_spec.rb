# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::DeleteOrphanedStageRecords,
  feature_category: :continuous_integration, migration: :gitlab_ci do
  let(:pipelines_table) { table(:p_ci_pipelines, database: :ci, primary_key: :id) }
  let(:stages_table) { table(:p_ci_stages, database: :ci, primary_key: :id) }

  let(:default_attributes) { { project_id: 600, partition_id: 100 } }
  let!(:regular_pipeline) { pipelines_table.create!(id: 1, **default_attributes) }
  let!(:deleted_pipeline) { pipelines_table.create!(id: 2, **default_attributes) }
  let!(:other_pipeline) { pipelines_table.create!(id: 3, **default_attributes) }

  let!(:regular_build) do
    stages_table.create!(pipeline_id: regular_pipeline.id, **default_attributes)
  end

  let!(:orphaned_build) do
    stages_table.create!(pipeline_id: deleted_pipeline.id, **default_attributes)
  end

  let(:connection) { Ci::ApplicationRecord.connection }

  around do |example|
    connection.transaction do
      connection.execute(<<~SQL)
        ALTER TABLE ci_pipelines DISABLE TRIGGER ALL;
      SQL

      example.run

      connection.execute(<<~SQL)
        ALTER TABLE ci_pipelines ENABLE TRIGGER ALL;
      SQL
    end
  end

  describe '#perform' do
    subject(:migration) do
      described_class.new(
        start_id: stages_table.minimum(:pipeline_id),
        end_id: stages_table.maximum(:pipeline_id),
        batch_table: :p_ci_stages,
        batch_column: :pipeline_id,
        sub_batch_size: 100,
        pause_ms: 0,
        connection: connection
      )
    end

    it 'deletes from p_ci_stages where pipeline_id has no related record at p_ci_pipelines.id', :aggregate_failures do
      expect { deleted_pipeline.delete }.to not_change { stages_table.count }

      expect { migration.perform }.to change { stages_table.count }.from(2).to(1)

      expect(regular_build.reload).to be_persisted
      expect { orphaned_build.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
