# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe BackfillProjectStatisticsStorageSizeWithoutPipelineArtifactsSize, feature_category: :consumables_cost_management do
  let!(:batched_migration) { described_class::MIGRATION }

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

  it 'schedules a new batched migration' do
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
          interval: described_class::DELAY_INTERVAL,
          batch_size: described_class::BATCH_SIZE,
          sub_batch_size: described_class::SUB_BATCH_SIZE
        )
      }
    end
  end
end
