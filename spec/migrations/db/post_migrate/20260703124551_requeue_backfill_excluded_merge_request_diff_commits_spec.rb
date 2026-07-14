# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe RequeueBackfillExcludedMergeRequestDiffCommits, migration: :gitlab_main_cell_local,
  feature_category: :code_review_workflow do
  let!(:batched_migration) { described_class::MIGRATION }

  context 'when on GitLab.com' do
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
            table_name: :excluded_merge_requests,
            column_name: :id,
            batch_size: described_class::BATCH_SIZE,
            sub_batch_size: described_class::SUB_BATCH_SIZE,
            max_batch_size: described_class::MAX_BATCH_SIZE
          )
        }
      end
    end
  end

  context 'when not on GitLab.com' do
    before do
      allow(Gitlab).to receive(:com_except_jh?).and_return(false)
    end

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
