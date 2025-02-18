# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe QueueBackfillPartitionWebHookLogDaily, feature_category: :integrations do
  let!(:batched_migration) { described_class::MIGRATION }

  context 'when executed on .com' do
    before do
      allow(Gitlab).to receive(:com_except_jh?).and_return(true)
    end

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
  end

  context 'when executed on self managed' do
    before do
      allow(Gitlab).to receive(:com_except_jh?).and_return(false)
    end

    it 'schedules a new batched migration' do
      reversible_migration do |migration|
        migration.before -> {
          expect(batched_migration).not_to have_scheduled_batched_migration
        }

        migration.after -> {
          expect(batched_migration).to have_scheduled_batched_migration(
            table_name: :web_hook_logs,
            column_name: :id,
            interval: described_class::DELAY_INTERVAL,
            batch_size: described_class::BATCH_SIZE,
            sub_batch_size: described_class::SUB_BATCH_SIZE
          )
        }
      end
    end
  end
end
