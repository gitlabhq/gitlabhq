# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe QueueBackfillCiPipelineMessagesProjectId, migration: :gitlab_ci, feature_category: :continuous_integration do
  let!(:batched_migration) { described_class::MIGRATION }

  it 'schedules a new batched migration' do
    reversible_migration do |migration|
      migration.before -> {
        expect(batched_migration).not_to have_scheduled_batched_migration
      }

      migration.after -> {
        expect(batched_migration).to have_scheduled_batched_migration(
          table_name: :ci_pipeline_messages,
          column_name: :id,
          interval: described_class::DELAY_INTERVAL,
          gitlab_schema: :gitlab_ci,
          job_arguments: [
            :project_id,
            :p_ci_pipelines,
            :project_id,
            :pipeline_id,
            :partition_id
          ]
        )
      }
    end
  end
end
