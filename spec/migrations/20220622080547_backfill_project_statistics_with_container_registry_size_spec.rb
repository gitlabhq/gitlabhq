# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe BackfillProjectStatisticsWithContainerRegistrySize, feature_category: :container_registry do
  let!(:batched_migration) { described_class::MIGRATION_CLASS }

  it 'does not schedule background jobs when Gitlab.com is false' do
    allow(Gitlab).to receive(:com?).and_return(false)
    allow(Gitlab).to receive(:dev_or_test_env?).and_return(false)

    reversible_migration do |migration|
      migration.before -> {
        expect(batched_migration).not_to have_scheduled_batched_migration
      }

      migration.after -> {
        expect(batched_migration).not_to have_scheduled_batched_migration
      }
    end
  end

  it 'schedules background jobs for each batch of container_repository' do
    allow(Gitlab).to receive(:com?).and_return(true)

    reversible_migration do |migration|
      migration.before -> {
        expect(batched_migration).not_to have_scheduled_batched_migration
      }

      migration.after -> {
        expect(batched_migration).to have_scheduled_batched_migration(
          table_name: :container_repositories,
          column_name: :project_id,
          interval: described_class::DELAY_INTERVAL
        )
      }
    end
  end
end
