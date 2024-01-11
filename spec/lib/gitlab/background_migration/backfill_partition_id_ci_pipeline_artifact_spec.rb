# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillPartitionIdCiPipelineArtifact,
  feature_category: :continuous_integration do
  let(:ci_pipelines_table) { table(:ci_pipelines, database: :ci) }
  let(:ci_pipeline_artifacts_table) { table(:ci_pipeline_artifacts, database: :ci) }
  let!(:pipeline_100) { ci_pipelines_table.create!(id: 1, partition_id: 100) }
  let!(:pipeline_101) { ci_pipelines_table.create!(id: 2, partition_id: 101) }
  let!(:pipeline_102) { ci_pipelines_table.create!(id: 3, partition_id: 101) }
  let!(:ci_pipeline_artifact_100) do
    ci_pipeline_artifacts_table.create!(
      id: 1,
      pipeline_id: pipeline_100.id,
      project_id: 1,
      size: 1.megabyte,
      file_type: 1,
      file_format: 1,
      file: fixture_file_upload(
        Rails.root.join('spec/fixtures/pipeline_artifacts/code_coverage.json'), 'application/json'
      ),
      partition_id: pipeline_100.partition_id
    )
  end

  let!(:ci_pipeline_artifact_101) do
    ci_pipeline_artifacts_table.create!(
      id: 2,
      pipeline_id: pipeline_101.id,
      project_id: 1,
      size: 1.megabyte,
      file_type: 1,
      file_format: 1,
      file: fixture_file_upload(
        Rails.root.join('spec/fixtures/pipeline_artifacts/code_coverage.json'), 'application/json'
      ),
      partition_id: pipeline_101.partition_id
    )
  end

  let!(:invalid_ci_pipeline_artifact) do
    ci_pipeline_artifacts_table.create!(
      id: 3,
      pipeline_id: pipeline_102.id,
      project_id: 1,
      size: 1.megabyte,
      file_type: 1,
      file_format: 1,
      file: fixture_file_upload(
        Rails.root.join('spec/fixtures/pipeline_artifacts/code_coverage.json'), 'application/json'
      ),
      partition_id: pipeline_100.partition_id
    )
  end

  let(:migration_attrs) do
    {
      start_id: ci_pipeline_artifacts_table.minimum(:pipeline_id),
      end_id: ci_pipeline_artifacts_table.maximum(:pipeline_id),
      batch_table: :ci_pipeline_artifacts,
      batch_column: :id,
      sub_batch_size: 1,
      pause_ms: 0,
      connection: Ci::ApplicationRecord.connection
    }
  end

  let!(:migration) { described_class.new(**migration_attrs) }

  describe '#perform' do
    context 'when second partition does not exist' do
      it 'does not execute the migration' do
        expect { migration.perform }
          .not_to change { invalid_ci_pipeline_artifact.reload.partition_id }
      end
    end

    context 'when second partition exists' do
      before do
        allow(migration).to receive(:uses_multiple_partitions?).and_return(true)
      end

      it 'fixes invalid records in the wrong the partition' do
        expect { migration.perform }
          .to not_change { ci_pipeline_artifact_100.reload.partition_id }
          .and not_change { ci_pipeline_artifact_101.reload.partition_id }
          .and change { invalid_ci_pipeline_artifact.reload.partition_id }
          .from(100)
          .to(101)
      end
    end
  end
end
