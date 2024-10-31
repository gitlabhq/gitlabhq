# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillOrDropCiPipelineOnProjectId,
  :suppress_partitioning_routing_analyzer,
  feature_category: :continuous_integration,
  migration: :gitlab_ci do
  let(:project_id_with_build) { 137 }
  let(:project_id_for_merge_request) { 140 }
  let(:project_id_for_unaffected_pipeline) { 1 }

  let!(:pipeline_with_nothing) do
    table(:ci_pipelines, primary_key: :id, database: :ci).create!(id: 1, partition_id: 100)
  end

  let!(:pipeline_with_builds) do
    table(:ci_pipelines, primary_key: :id, database: :ci).create!(id: 2, partition_id: 100)
  end

  let!(:pipeline_with_merge_request) do
    table(:ci_pipelines, primary_key: :id, database: :ci).create!(id: 3, partition_id: 100, merge_request_id: 1)
  end

  let!(:untouched_pipeline) do
    table(:ci_pipelines, primary_key: :id, database: :ci)
      .create!(id: 4, partition_id: 100, project_id: project_id_for_unaffected_pipeline)
  end

  let!(:ci_trigger) { table(:ci_triggers, database: :ci).create!(owner_id: 1) }
  let!(:trigger_request) { table(:ci_trigger_requests, database: :ci).create!(trigger_id: ci_trigger.id, commit_id: 1) }
  let!(:build) do
    table(:p_ci_builds, database: :ci).create!(partition_id: 100, project_id: project_id_with_build, commit_id: 2)
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
    before do
      allow(Gitlab::BackgroundMigration::BackfillOrDropCiPipelineOnProjectId::MergeRequest)
        .to receive_message_chain(:where, :select)
        .and_return([])
    end

    it 'backfills if applicable otherwise deletes' do
      migration.perform

      expect { pipeline_with_nothing.reload }.to raise_error(ActiveRecord::RecordNotFound)
      expect { trigger_request.reload }.to raise_error(ActiveRecord::RecordNotFound)
      expect(pipeline_with_builds.reload.project_id).to eq(project_id_with_build)
      expect(untouched_pipeline.reload.project_id).to eq(project_id_for_unaffected_pipeline)
    end

    context 'for migrations with merge_request' do
      before do
        merge_request = double('merge_request') # rubocop:disable RSpec/VerifiedDoubles -- merge_request is a already a stub of applicationRecord
        allow(merge_request).to receive(:target_project_id) { project_id_for_merge_request }

        allow(Gitlab::BackgroundMigration::BackfillOrDropCiPipelineOnProjectId::MergeRequest)
          .to receive_message_chain(:where, :select)
          .and_return([merge_request])
      end

      it 'backfills from merge_request' do
        migration.perform

        expect(pipeline_with_merge_request.reload.project_id).to eq(project_id_for_merge_request)
      end
    end

    context 'when backfill will create an invalid record' do
      before do
        table(:ci_pipelines, primary_key: :id, database: :ci)
          .create!(id: 100, iid: 100, partition_id: 100, project_id: 137)

        pipeline_with_builds.update!(iid: 100)
      end

      it 'deletes the pipeline instead' do
        migration.perform

        expect { pipeline_with_builds.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'when associations are invalid as well' do
      let!(:pipeline_with_bad_build) do
        table(:ci_pipelines, primary_key: :id, database: :ci).create!(id: 5, partition_id: 100)
      end

      let!(:bad_build) { table(:p_ci_builds, database: :ci).create!(partition_id: 100, commit_id: 5) }

      it 'deletes pipeline if associations do not have project_id' do
        migration.perform

        expect { pipeline_with_bad_build.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
