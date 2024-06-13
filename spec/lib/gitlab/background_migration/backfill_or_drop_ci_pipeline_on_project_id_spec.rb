# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillOrDropCiPipelineOnProjectId, feature_category: :continuous_integration do
  let(:project_id_with_build) { 137 }
  let(:project_id_for_merge_request) { 140 }
  let(:project_id_for_unaffected_pipeline) { 1 }

  let!(:pipeline_with_nothing) { table(:ci_pipelines, database: :ci).create!(id: 1, partition_id: 100) }
  let!(:pipeline_with_builds) { table(:ci_pipelines, database: :ci).create!(id: 2, partition_id: 100) }
  let!(:pipeline_with_merge_request) do
    table(:ci_pipelines, database: :ci).create!(id: 3, partition_id: 100, merge_request_id: 1)
  end

  let!(:untouched_pipeline) do
    table(:ci_pipelines, database: :ci)
      .create!(id: 4, partition_id: 100, project_id: project_id_for_unaffected_pipeline)
  end

  let!(:ci_trigger) { table(:ci_triggers, database: :ci).create!(owner_id: 1) }
  let!(:trigger_request) { table(:ci_trigger_requests, database: :ci).create!(trigger_id: ci_trigger.id, commit_id: 1) }
  let!(:build) do
    table(:p_ci_builds, database: :ci).create!(partition_id: 100, project_id: project_id_with_build, commit_id: 2)
  end

  let(:namespace) { table(:namespaces).create!(name: 'user', path: 'user') }
  let(:project) do
    table(:projects)
      .create!(id: project_id_for_merge_request, namespace_id: namespace.id, project_namespace_id: namespace.id)
  end

  let!(:merge_request) do
    table(:merge_requests).create!(
      id: 1,
      target_branch: 'main',
      source_branch: 'feature',
      target_project_id: project.id,
      source_project_id: project.id
    )
  end

  subject(:migration) do
    described_class.new(
      start_id: 1,
      end_id: 5,
      batch_table: :ci_pipelines,
      batch_column: :id,
      sub_batch_size: 100,
      pause_ms: 0,
      connection: ::Ci::ApplicationRecord.connection
    )
  end

  describe '#perform' do
    it 'backfills if applicable otherwise deletes' do
      migration.perform

      expect { pipeline_with_nothing.reload }.to raise_error(ActiveRecord::RecordNotFound)
      expect { trigger_request.reload }.to raise_error(ActiveRecord::RecordNotFound)
      expect(pipeline_with_builds.reload.project_id).to eq(project_id_with_build)
      expect(pipeline_with_merge_request.reload.project_id).to eq(project_id_for_merge_request)
      expect(untouched_pipeline.reload.project_id).to eq(project_id_for_unaffected_pipeline)
    end

    context 'when associations are invalid as well' do
      let!(:pipeline_with_bad_build) { table(:ci_pipelines, database: :ci).create!(id: 5, partition_id: 100) }
      let!(:bad_build) { table(:p_ci_builds, database: :ci).create!(partition_id: 100, commit_id: 5) }

      it 'deletes pipeline if associations do not have project_id' do
        migration.perform

        expect { pipeline_with_bad_build.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'when the merge request is from a fork project' do
      let(:another_namespace) { table(:namespaces).create!(name: 'user2', path: 'user2') }

      let(:another_project) do
        table(:projects)
          .create!(id: 141, namespace_id: another_namespace.id, project_namespace_id: another_namespace.id)
      end

      let!(:merge_request) do
        table(:merge_requests).create!(
          id: 1,
          target_branch: 'main',
          source_branch: 'feature',
          target_project_id: project.id,
          source_project_id: another_project.id
        )
      end

      it 'deletes the pipeline as association is not definite' do
        migration.perform

        expect { pipeline_with_merge_request.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
