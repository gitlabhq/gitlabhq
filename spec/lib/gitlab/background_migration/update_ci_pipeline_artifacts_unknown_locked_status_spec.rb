# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::UpdateCiPipelineArtifactsUnknownLockedStatus, feature_category: :build_artifacts do
  describe '#perform' do
    let(:batch_table) { :ci_pipeline_artifacts }
    let(:batch_column) { :id }

    let(:sub_batch_size) { 1 }
    let(:pause_ms) { 0 }
    let(:connection) { Ci::ApplicationRecord.connection }

    let(:namespaces) { table(:namespaces) }
    let(:projects) { table(:projects) }
    let(:pipelines) { table(:ci_pipelines, database: :ci) }
    let(:pipeline_artifacts) { table(:ci_pipeline_artifacts, database: :ci) }

    let(:namespace) { namespaces.create!(name: 'name', path: 'path') }
    let(:project) do
      projects
        .create!(name: "project", path: "project", namespace_id: namespace.id, project_namespace_id: namespace.id)
    end

    let(:unlocked) { 0 }
    let(:locked) { 1 }
    let(:unknown) { 2 }

    let(:unlocked_pipeline) { pipelines.create!(locked: unlocked, partition_id: 100) }
    let(:locked_pipeline) { pipelines.create!(locked: locked, partition_id: 100) }

    # rubocop:disable Layout/LineLength
    let!(:locked_artifact) { pipeline_artifacts.create!(project_id: project.id, pipeline_id: locked_pipeline.id, size: 1024, file_type: 0, file_format: 'gzip', file: 'a.gz', locked: unknown, partition_id: 100) }
    let!(:unlocked_artifact_1) { pipeline_artifacts.create!(project_id: project.id, pipeline_id: unlocked_pipeline.id, size: 2048, file_type: 1, file_format: 'raw', file: 'b', locked: unknown, partition_id: 100) }
    let!(:unlocked_artifact_2) { pipeline_artifacts.create!(project_id: project.id, pipeline_id: unlocked_pipeline.id, size: 4096, file_type: 2, file_format: 'gzip', file: 'c.gz', locked: unknown, partition_id: 100) }
    let!(:already_unlocked_artifact) { pipeline_artifacts.create!(project_id: project.id, pipeline_id: unlocked_pipeline.id, size: 8192, file_type: 3, file_format: 'raw', file: 'd', locked: unlocked, partition_id: 100) }
    let!(:already_locked_artifact) { pipeline_artifacts.create!(project_id: project.id, pipeline_id: locked_pipeline.id, size: 8192, file_type: 3, file_format: 'raw', file: 'd', locked: locked, partition_id: 100) }
    # rubocop:enable Layout/LineLength

    subject do
      described_class.new(
        start_id: locked_artifact.id,
        end_id: already_locked_artifact.id,
        batch_table: batch_table,
        batch_column: batch_column,
        sub_batch_size: sub_batch_size,
        pause_ms: pause_ms,
        connection: connection
      ).perform
    end

    it 'updates ci_pipeline_artifacts with unknown lock status' do
      subject

      expect(locked_artifact.reload.locked).to eq(locked)
      expect(unlocked_artifact_1.reload.locked).to eq(unlocked)
      expect(unlocked_artifact_2.reload.locked).to eq(unlocked)
      expect(already_unlocked_artifact.reload.locked).to eq(unlocked)
      expect(already_locked_artifact.reload.locked).to eq(locked)
    end
  end
end
