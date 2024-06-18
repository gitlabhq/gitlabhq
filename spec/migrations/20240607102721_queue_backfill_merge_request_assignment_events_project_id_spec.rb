# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe QueueBackfillMergeRequestAssignmentEventsProjectId, feature_category: :value_stream_management do
  let!(:batched_migration) { described_class::MIGRATION }

  it 'schedules a new batched migration' do
    reversible_migration do |migration|
      migration.before -> {
        expect(batched_migration).not_to have_scheduled_batched_migration
      }

      migration.after -> {
        expect(batched_migration).to have_scheduled_batched_migration(
          table_name: :merge_request_assignment_events,
          column_name: :id,
          interval: described_class::DELAY_INTERVAL,
          batch_size: described_class::BATCH_SIZE,
          sub_batch_size: described_class::SUB_BATCH_SIZE,
          gitlab_schema: :gitlab_main_cell,
          job_arguments: [
            :project_id,
            :merge_requests,
            :target_project_id,
            :merge_request_id
          ]
        )
      }
    end
  end
end
