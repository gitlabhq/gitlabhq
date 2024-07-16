# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe QueueBackfillIssuesDatesWithWorkItemDatesSources, feature_category: :team_planning do
  let!(:batched_migration) { described_class::MIGRATION }

  it 'schedules a new batched migration' do
    reversible_migration do |migration|
      migration.before -> {
        expect(batched_migration).not_to have_scheduled_batched_migration
      }

      migration.after -> {
        expect(batched_migration).to have_scheduled_batched_migration(
          table_name: :work_item_dates_sources,
          column_name: :issue_id,
          interval: described_class::DELAY_INTERVAL,
          batch_size: described_class::BATCH_SIZE
        )
      }
    end
  end
end
