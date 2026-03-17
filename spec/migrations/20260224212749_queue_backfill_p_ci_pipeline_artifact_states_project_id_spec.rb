# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe QueueBackfillPCiPipelineArtifactStatesProjectId, feature_category: :geo_replication, migration: :gitlab_ci do
  let!(:batched_migration) { described_class::MIGRATION }

  it 'schedules a new batched migration' do
    reversible_migration do |migration|
      migration.before -> {
        expect(batched_migration).not_to have_scheduled_batched_migration
      }

      migration.after -> {
        expect(batched_migration).to have_scheduled_batched_migration(
          table_name: :p_ci_pipeline_artifact_states,
          column_name: :pipeline_artifact_id,
          interval: described_class::DELAY_INTERVAL,
          batch_size: described_class::BATCH_SIZE,
          sub_batch_size: described_class::SUB_BATCH_SIZE,
          gitlab_schema: :gitlab_ci,
          job_arguments: [
            :project_id,
            :ci_pipeline_artifacts,
            :project_id,
            :pipeline_artifact_id
          ]
        )
      }
    end
  end
end
