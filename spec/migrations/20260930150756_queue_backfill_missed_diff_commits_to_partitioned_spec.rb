# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe QueueBackfillMissedDiffCommitsToPartitioned, migration: :gitlab_main_org,
  feature_category: :code_review_workflow do
  let(:migration_name) { described_class::MIGRATION }

  def scheduled_record
    Gitlab::Database::BackgroundMigration::BatchedMigration.find_by(
      job_class_name: migration_name,
      table_name: described_class::SOURCE_TABLE
    )
  end

  context 'when on GitLab.com', :aggregate_failures do
    before do
      allow(Gitlab).to receive(:com_except_jh?).and_return(true)
    end

    describe '#up' do
      it 'schedules the batched migration against the archived table' do
        reversible_migration do |migration|
          migration.before -> {
            expect(migration_name).not_to have_scheduled_batched_migration
          }

          migration.after -> {
            expect(migration_name).to have_scheduled_batched_migration(
              gitlab_schema: :gitlab_main_org,
              table_name: described_class::SOURCE_TABLE,
              column_name: :merge_request_diff_id,
              interval: 2.minutes,
              batch_size: described_class::BATCH_SIZE,
              sub_batch_size: described_class::SUB_BATCH_SIZE,
              max_batch_size: described_class::MAX_BATCH_SIZE,
              job_arguments: [described_class::TARGET_TABLE]
            )
          }
        end
      end

      it 'bounds the cursor to the flag rollout window' do
        migrate!

        expect(scheduled_record.min_cursor).to eq([described_class::MIN_DIFF_ID, 0])
        expect(scheduled_record.max_cursor).to eq(
          [described_class::MAX_DIFF_ID, described_class::MAX_RELATIVE_ORDER]
        )
      end

      it 'sizes total_tuple_count to the cursor window rather than the whole table' do
        migrate!

        expect(scheduled_record.total_tuple_count).to eq(described_class::TUPLE_COUNT)
      end
    end

    describe '#down' do
      it 'deletes the batched migration' do
        migrate!

        expect(scheduled_record).to be_present

        schema_migrate_down!

        expect(scheduled_record).to be_nil
      end
    end
  end

  context 'when not on GitLab.com' do
    before do
      allow(Gitlab).to receive(:com_except_jh?).and_return(false)
    end

    describe '#up' do
      it 'does not schedule anything, because neither table carries these names' do
        reversible_migration do |migration|
          migration.before -> {
            expect(migration_name).not_to have_scheduled_batched_migration
          }

          migration.after -> {
            expect(migration_name).not_to have_scheduled_batched_migration
          }
        end
      end
    end
  end
end
