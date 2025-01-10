# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe QueueReEnqueueDeleteOrphanedGroups, migration: :gitlab_main, feature_category: :groups_and_projects do
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

  context 'when executed on .com' do
    before do
      allow(Gitlab).to receive(:com_except_jh?).and_return(true)
    end

    describe '#up' do
      it 'schedules background migration' do
        migrate!

        expect(batched_migration).to have_scheduled_batched_migration(
          table_name: :namespaces,
          column_name: :id,
          interval: described_class::DELAY_INTERVAL,
          batch_size: described_class::BATCH_SIZE,
          sub_batch_size: described_class::SUB_BATCH_SIZE
        )
      end
    end

    describe '#down' do
      it 'removes scheduled background migrations' do
        migrate!
        schema_migrate_down!

        expect(batched_migration).not_to have_scheduled_batched_migration
      end
    end
  end
end
