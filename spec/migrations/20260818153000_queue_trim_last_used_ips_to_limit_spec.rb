# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe QueueTrimLastUsedIpsToLimit, migration: :gitlab_main_org, feature_category: :system_access do
  let!(:batched_migration) { described_class::MIGRATION }

  it 'schedules a new batched migration' do
    reversible_migration do |migration|
      migration.before -> {
        expect(batched_migration).not_to have_scheduled_batched_migration
      }

      migration.after -> {
        expect(batched_migration).to have_scheduled_batched_migration(
          gitlab_schema: :gitlab_main_org,
          table_name: :personal_access_token_last_used_ips,
          column_name: :id,
          interval: described_class::DELAY_INTERVAL,
          batch_size: described_class::BATCH_SIZE,
          sub_batch_size: described_class::SUB_BATCH_SIZE,
          pause_ms: described_class::PAUSE_MS
        )
      }
    end
  end
end
