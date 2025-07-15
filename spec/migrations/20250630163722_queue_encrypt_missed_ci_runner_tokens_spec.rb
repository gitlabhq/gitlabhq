# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe QueueEncryptMissedCiRunnerTokens, migration: :gitlab_ci, feature_category: :fleet_visibility do
  let!(:batched_migration) { described_class::MIGRATION }

  it 'schedules a new batched migration' do
    reversible_migration do |migration|
      migration.before -> {
        expect(batched_migration).not_to have_scheduled_batched_migration
      }

      migration.after -> {
        expect(batched_migration).to have_scheduled_batched_migration(
          gitlab_schema: :gitlab_ci,
          table_name: :ci_runners,
          column_name: :id
        )
      }
    end
  end
end
