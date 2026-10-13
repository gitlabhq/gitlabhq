# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe QueueBackfillDriftedWorkItemTransitions, migration: :gitlab_main, feature_category: :team_planning do
  let!(:batched_migration) { described_class::MIGRATION }

  context 'when run on GitLab.com' do
    before do
      allow(Gitlab).to receive(:com_except_jh?).and_return(true)
    end

    it 'schedules a new batched migration' do
      reversible_migration do |migration|
        migration.before -> {
          expect(batched_migration).not_to have_scheduled_batched_migration
        }

        migration.after -> {
          expect(batched_migration).to have_scheduled_batched_migration(
            gitlab_schema: :gitlab_main_org,
            table_name: :work_item_transitions,
            column_name: :work_item_id,
            batch_size: described_class::BATCH_SIZE,
            sub_batch_size: described_class::SUB_BATCH_SIZE
          )
        }
      end
    end
  end

  context 'when run anywhere else' do
    before do
      allow(Gitlab).to receive(:com_except_jh?).and_return(false)
    end

    # Only GitLab.com ran the swap before the trigger was rebound, so no other instance can have
    # drifted rows to repair.
    it 'does not schedule a batched migration' do
      reversible_migration do |migration|
        migration.before -> {
          expect(batched_migration).not_to have_scheduled_batched_migration
        }

        migration.after -> {
          expect(batched_migration).not_to have_scheduled_batched_migration
        }
      end
    end
  end
end
