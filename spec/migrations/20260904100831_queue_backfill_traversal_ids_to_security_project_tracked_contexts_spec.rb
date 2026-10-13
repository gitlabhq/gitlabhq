# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe QueueBackfillTraversalIdsToSecurityProjectTrackedContexts, migration: :gitlab_sec, feature_category: :vulnerability_management do
  let!(:batched_migration) { described_class::MIGRATION }

  it 'schedules a new batched migration' do
    reversible_migration do |migration|
      migration.before -> {
        expect(batched_migration).not_to have_scheduled_batched_migration
      }

      migration.after -> {
        expect(batched_migration).to have_scheduled_batched_migration(
          gitlab_schema: :gitlab_sec,
          table_name: :security_project_tracked_contexts,
          column_name: :id,
          batch_size: described_class::BATCH_SIZE,
          sub_batch_size: described_class::SUB_BATCH_SIZE,
          interval: described_class::DELAY_INTERVAL
        )
      }
    end
  end
end
