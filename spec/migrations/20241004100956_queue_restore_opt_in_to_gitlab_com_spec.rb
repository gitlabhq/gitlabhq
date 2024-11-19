# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe QueueRestoreOptInToGitlabCom, feature_category: :activation do
  let!(:batched_migration) { described_class::MIGRATION }

  it 'does not schedule a new batched migration' do
    reversible_migration do |migration|
      migration.before -> {
        expect(batched_migration).not_to have_scheduled_batched_migration
      }

      migration.after -> {
        expect(batched_migration).not_to have_scheduled_batched_migration
      }
    end
  end

  context 'when SaaS', :saas do
    it 'does not schedule a new batched migration' do
      reversible_migration do |migration|
        migration.before -> {
          expect(batched_migration).not_to have_scheduled_batched_migration
        }

        migration.after -> {
          expect(batched_migration).not_to have_scheduled_batched_migration
        }
      end
    end

    context 'when the temporary table exists' do
      before do
        allow(ApplicationRecord.connection).to receive(:table_exists?).and_return(true)
      end

      it 'schedules a new batched migration' do
        reversible_migration do |migration|
          migration.before -> {
            expect(batched_migration).not_to have_scheduled_batched_migration
          }

          migration.after -> {
            expect(batched_migration).to have_scheduled_batched_migration(
              table_name: described_class::TABLE_NAME,
              column_name: described_class::BATCH_COLUMN,
              job_arguments: [described_class::TEMPORARY_TABLE_NAME],
              interval: described_class::DELAY_INTERVAL,
              batch_size: described_class::BATCH_SIZE,
              sub_batch_size: described_class::SUB_BATCH_SIZE,
              max_batch_size: described_class::MAX_BATCH_SIZE
            )
          }
        end
      end
    end
  end
end
