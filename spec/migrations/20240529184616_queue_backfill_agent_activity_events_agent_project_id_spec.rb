# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe QueueBackfillAgentActivityEventsAgentProjectId, feature_category: :deployment_management do
  let!(:batched_migration) { described_class::MIGRATION }

  it 'schedules a new batched migration' do
    reversible_migration do |migration|
      migration.before -> {
        expect(batched_migration).not_to have_scheduled_batched_migration
      }

      migration.after -> {
        expect(batched_migration).to have_scheduled_batched_migration(
          table_name: :agent_activity_events,
          column_name: :id,
          interval: described_class::DELAY_INTERVAL,
          batch_size: described_class::BATCH_SIZE,
          sub_batch_size: described_class::SUB_BATCH_SIZE,
          gitlab_schema: :gitlab_main_org,
          job_arguments: [
            :agent_project_id,
            :cluster_agents,
            :project_id,
            :agent_id
          ]
        )
      }
    end
  end
end
