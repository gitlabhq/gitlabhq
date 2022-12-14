# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe AdjustTaskNoteRenameBackgroundMigrationValues, :migration, feature_category: :team_planning do
  let(:finished_status) { 3 }
  let(:failed_status) { described_class::MIGRATION_FAILED_STATUS }
  let(:active_status) { described_class::MIGRATION_ACTIVE_STATUS }

  shared_examples 'task note migration with failing batches' do
    it 'updates batch sizes and resets failed batches' do
      migration = create_background_migration(status: initial_status)
      batches = []

      batches << create_failed_batched_job(migration)
      batches << create_failed_batched_job(migration)

      migrate!

      expect(described_class::JOB_CLASS_NAME).to have_scheduled_batched_migration(
        table_name: :system_note_metadata,
        column_name: :id,
        interval: 2.minutes,
        batch_size: described_class::NEW_BATCH_SIZE,
        max_batch_size: 20_000,
        sub_batch_size: described_class::NEW_SUB_BATCH_SIZE
      )
      expect(migration.reload.status).to eq(active_status)

      updated_batches = batches.map { |b| b.reload.attributes.slice('attempts', 'sub_batch_size') }
      expect(updated_batches).to all(eq("attempts" => 0, "sub_batch_size" => 10))
    end
  end

  describe '#up' do
    context 'when migration was already finished' do
      it 'does not update batch sizes' do
        create_background_migration(status: finished_status)

        migrate!

        expect(described_class::JOB_CLASS_NAME).to have_scheduled_batched_migration(
          table_name: :system_note_metadata,
          column_name: :id,
          interval: 2.minutes,
          batch_size: described_class::OLD_BATCH_SIZE,
          max_batch_size: 20_000,
          sub_batch_size: described_class::OLD_SUB_BATCH_SIZE
        )
      end
    end

    context 'when the migration had failing batches' do
      context 'when migration had a failed status' do
        it_behaves_like 'task note migration with failing batches' do
          let(:initial_status) { failed_status }
        end

        it 'updates started_at timestamp' do
          migration = create_background_migration(status: failed_status)
          now = Time.zone.now

          travel_to now do
            migrate!
            migration.reload
          end

          expect(migration.started_at).to be_like_time(now)
        end
      end

      context 'when migration had an active status' do
        it_behaves_like 'task note migration with failing batches' do
          let(:initial_status) { active_status }
        end

        it 'does not update started_at timestamp' do
          migration = create_background_migration(status: active_status)
          original_time = migration.started_at

          migrate!
          migration.reload

          expect(migration.started_at).to be_like_time(original_time)
        end
      end
    end
  end

  describe '#down' do
    it 'reverts to old batch sizes' do
      create_background_migration(status: finished_status)

      migrate!
      schema_migrate_down!

      expect(described_class::JOB_CLASS_NAME).to have_scheduled_batched_migration(
        table_name: :system_note_metadata,
        column_name: :id,
        interval: 2.minutes,
        batch_size: described_class::OLD_BATCH_SIZE,
        max_batch_size: 20_000,
        sub_batch_size: described_class::OLD_SUB_BATCH_SIZE
      )
    end
  end

  def create_failed_batched_job(migration)
    table(:batched_background_migration_jobs).create!(
      batched_background_migration_id: migration.id,
      status: described_class::JOB_FAILED_STATUS,
      min_value: 1,
      max_value: 10,
      attempts: 3,
      batch_size: described_class::OLD_BATCH_SIZE,
      sub_batch_size: described_class::OLD_SUB_BATCH_SIZE
    )
  end

  def create_background_migration(status:)
    migrations_table = table(:batched_background_migrations)
    # make sure we only have on migration with that job class name in the specs
    migrations_table.where(job_class_name: described_class::JOB_CLASS_NAME).delete_all

    migrations_table.create!(
      job_class_name: described_class::JOB_CLASS_NAME,
      status: status,
      max_value: 10,
      max_batch_size: 20_000,
      batch_size: described_class::OLD_BATCH_SIZE,
      sub_batch_size: described_class::OLD_SUB_BATCH_SIZE,
      interval: 2.minutes,
      table_name: :system_note_metadata,
      column_name: :id,
      total_tuple_count: 100_000,
      pause_ms: 100,
      gitlab_schema: :gitlab_main,
      job_arguments: [],
      started_at: 2.days.ago
    )
  end
end
