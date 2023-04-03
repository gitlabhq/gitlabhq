# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe BackfillProjectStatisticsStorageSizeWithoutUploadsSize,
  feature_category: :consumables_cost_management do
  let!(:batched_migration) { described_class::MIGRATION_CLASS }

  it 'does not schedule background jobs when Gitlab.org_or_com? is false' do
    allow(Gitlab).to receive(:dev_or_test_env?).and_return(false)
    allow(Gitlab).to receive(:org_or_com?).and_return(false)

    reversible_migration do |migration|
      migration.before -> {
        expect(batched_migration).not_to have_scheduled_batched_migration
      }

      migration.after -> {
        expect(batched_migration).not_to have_scheduled_batched_migration
      }
    end
  end

  it 'schedules background jobs for each batch of project_statistics' do
    allow(Gitlab).to receive(:dev_or_test_env?).and_return(false)
    allow(Gitlab).to receive(:org_or_com?).and_return(true)

    reversible_migration do |migration|
      migration.before -> {
        expect(batched_migration).not_to have_scheduled_batched_migration
      }

      migration.after -> {
        expect(batched_migration).to have_scheduled_batched_migration(
          table_name: :project_statistics,
          column_name: :project_id,
          interval: described_class::DELAY_INTERVAL
        )
      }
    end
  end
end
