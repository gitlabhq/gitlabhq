# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe RequeueBackfillCiRunnersPartitionedTable, migration: :gitlab_ci, feature_category: :runner do
  let!(:batched_migration) { 'BackfillCiRunnersPartitionedTable' }

  it 'schedules a new batched migration' do
    reversible_migration do |migration|
      migration.before -> {
        expect(batched_migration).not_to have_scheduled_batched_migration
      }

      migration.after -> {
        expect(batched_migration).to have_scheduled_batched_migration(
          table_name: :ci_runners,
          column_name: :id,
          interval: described_class::BATCH_INTERVAL,
          batch_size: described_class::BATCH_SIZE,
          sub_batch_size: described_class::SUB_BATCH_SIZE,
          job_arguments: ['ci_runners_e59bb2812d']
        )
      }
    end
  end
end
