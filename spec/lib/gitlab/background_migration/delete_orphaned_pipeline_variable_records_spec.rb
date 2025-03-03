# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::DeleteOrphanedPipelineVariableRecords,
  feature_category: :continuous_integration, migration: :gitlab_ci do
  let(:pipelines_table) { table(:p_ci_pipelines, primary_key: :id) }
  let(:variables_table) { table(:p_ci_pipeline_variables, primary_key: :id) }

  let(:default_attributes) { { project_id: 600, partition_id: 100 } }
  let!(:regular_pipeline) { pipelines_table.create!(default_attributes) }
  let!(:deleted_pipeline) { pipelines_table.create!(default_attributes) }
  let!(:other_pipeline) { pipelines_table.create!(default_attributes) }

  let!(:regular_variable) do
    variables_table.create!(pipeline_id: regular_pipeline.id, key: :key1, **default_attributes)
  end

  let!(:orphaned_variable) do
    variables_table.create!(pipeline_id: deleted_pipeline.id, key: :key2, **default_attributes)
  end

  let(:connection) { Ci::ApplicationRecord.connection }

  describe '#perform' do
    subject(:migration) do
      described_class.new(
        start_id: variables_table.minimum(:pipeline_id),
        end_id: variables_table.maximum(:pipeline_id),
        batch_table: :p_ci_pipeline_variables,
        batch_column: :pipeline_id,
        sub_batch_size: 100,
        pause_ms: 0,
        connection: connection
      )
    end

    it 'deletes from p_ci_pipeline_variables where pipeline_id has no related', :aggregate_failures do
      expect { without_referential_integrity { deleted_pipeline.delete } }.to not_change { variables_table.count }

      expect { migration.perform }.to change { variables_table.count }.from(2).to(1)

      expect(regular_variable.reload).to be_persisted
      expect { orphaned_variable.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end

    def without_referential_integrity
      connection.transaction do
        connection.execute('ALTER TABLE ci_pipelines DISABLE TRIGGER ALL;')
        result = yield
        connection.execute('ALTER TABLE ci_pipelines ENABLE TRIGGER ALL;')
        result
      end
    end
  end
end
