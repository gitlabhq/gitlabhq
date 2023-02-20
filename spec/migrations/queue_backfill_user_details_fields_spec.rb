# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe QueueBackfillUserDetailsFields, feature_category: :user_profile do
  let!(:batched_migration) { described_class::MIGRATION }

  it 'schedules a new batched migration' do
    reversible_migration do |migration|
      migration.before -> {
        expect(batched_migration).not_to have_scheduled_batched_migration
      }

      migration.after -> {
        expect(batched_migration).to have_scheduled_batched_migration(
          table_name: :users,
          column_name: :id,
          interval: described_class::INTERVAL
        )
      }
    end
  end
end
