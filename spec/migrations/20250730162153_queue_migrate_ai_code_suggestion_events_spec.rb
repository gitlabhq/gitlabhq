# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe QueueMigrateAiCodeSuggestionEvents, feature_category: :value_stream_management do
  let!(:batched_migration) { described_class::MIGRATION }

  it 'schedules a new batched migration' do
    reversible_migration do |migration|
      migration.before -> {
        expect(batched_migration).not_to have_scheduled_batched_migration
      }

      migration.after -> {
        expect(batched_migration).to have_scheduled_batched_migration(
          gitlab_schema: :gitlab_main_org,
          table_name: :ai_code_suggestion_events,
          column_name: :id,
          batch_size: described_class::BATCH_SIZE,
          sub_batch_size: described_class::SUB_BATCH_SIZE
        )
      }
    end
  end
end
