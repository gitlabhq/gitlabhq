# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe RescheduleBackfillImportedIssueSearchData do
  let_it_be(:reschedule_migration) { described_class::MIGRATION }

  context 'when BackfillIssueSearchData.max_value is nil' do
    it 'schedules a new batched migration with a default value' do
      reversible_migration do |migration|
        migration.before -> {
          expect(reschedule_migration).not_to have_scheduled_batched_migration
        }
        migration.after -> {
          expect(reschedule_migration).to have_scheduled_batched_migration(
            table_name: :issues,
            column_name: :id,
            interval: described_class::DELAY_INTERVAL,
            batch_min_value: described_class::BATCH_MIN_VALUE
          )
        }
      end
    end
  end

  context 'when BackfillIssueSearchData.max_value exists' do
    before do
      Gitlab::Database::BackgroundMigration::BatchedMigration
        .create!(
          max_value: 200,
          batch_size: 200,
          sub_batch_size: 20,
          interval: 120,
          job_class_name: 'BackfillIssueSearchData',
          table_name: 'issues',
          column_name: 'id',
          gitlab_schema: 'glschema'
        )
    end

    it 'schedules a new batched migration with a custom max_value' do
      reversible_migration do |migration|
        migration.after -> {
          expect(reschedule_migration).to have_scheduled_batched_migration(
            table_name: :issues,
            column_name: :id,
            interval: described_class::DELAY_INTERVAL,
            batch_min_value: 200
          )
        }
      end
    end
  end
end
