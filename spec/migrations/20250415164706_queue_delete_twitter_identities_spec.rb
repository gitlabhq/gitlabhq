# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe QueueDeleteTwitterIdentities, migration: :gitlab_main_clusterwide, feature_category: :system_access do
  let!(:batched_migration) { described_class::MIGRATION }

  it 'schedules a new batched migration' do
    reversible_migration do |migration|
      migration.before -> {
        expect(batched_migration).not_to have_scheduled_batched_migration
      }

      migration.after -> {
        expect(batched_migration).to have_scheduled_batched_migration(
          gitlab_schema: :gitlab_main_clusterwide,
          table_name: :identities,
          column_name: :id,
          batch_size: Gitlab::Database::Migrations::BatchedBackgroundMigrationHelpers::BATCH_SIZE
        )
      }
    end
  end
end
