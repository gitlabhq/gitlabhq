# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe QueueFixIncompleteInstanceExternalAuditDestinationsV2,
  migration: :gitlab_main,
  feature_category: :audit_events do
  let(:batched_migration) { described_class::MIGRATION }
  let(:old_migration) { 'FixIncompleteInstanceExternalAuditDestinations' }

  describe '#up' do
    it 'schedules a new batched migration and deletes the old one' do
      reversible_migration do |migration|
        migration.before -> {
          expect(batched_migration).not_to have_scheduled_batched_migration
        }

        migration.after -> {
          expect(batched_migration).to have_scheduled_batched_migration(
            table_name: :audit_events_instance_external_audit_event_destinations,
            column_name: :id,
            batch_size: described_class::BATCH_SIZE,
            sub_batch_size: described_class::SUB_BATCH_SIZE,
            gitlab_schema: :gitlab_main
          )
        }
      end
    end

    context 'when old migration exists' do
      let!(:old_batched_migration) do
        table(:batched_background_migrations).create!(
          job_class_name: old_migration,
          table_name: :audit_events_instance_external_audit_event_destinations,
          column_name: :id,
          job_arguments: [],
          interval: 2.minutes,
          min_value: 1,
          max_value: 2,
          batch_size: 100,
          sub_batch_size: 10,
          gitlab_schema: :gitlab_main,
          status: 3 # finished
        )
      end

      it 'deletes the old migration before scheduling the new one' do
        expect { migrate! }.to change {
          table(:batched_background_migrations)
            .where(job_class_name: old_migration)
            .count
        }.from(1).to(0)

        expect(batched_migration).to have_scheduled_batched_migration(
          table_name: :audit_events_instance_external_audit_event_destinations,
          column_name: :id,
          batch_size: described_class::BATCH_SIZE,
          sub_batch_size: described_class::SUB_BATCH_SIZE,
          gitlab_schema: :gitlab_main
        )
      end
    end
  end

  describe '#down' do
    it 'removes scheduled migration when rolling back' do
      disable_migrations_output do
        migrate!
        schema_migrate_down!
      end

      expect(batched_migration).not_to have_scheduled_batched_migration
    end
  end
end
