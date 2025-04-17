# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe QueueDeleteOrphanedCiRunnerMachineRecordsOnSelfManaged, migration: :gitlab_ci,
  feature_category: :fleet_visibility do
  let!(:batched_migration) { described_class::MIGRATION }

  before do
    allow(Gitlab).to receive(:com_except_jh?).and_return(gitlab_com_except_jh?)
  end

  context 'when it is on GitLab.com' do
    let(:gitlab_com_except_jh?) { true }

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

  context 'when it is not on GitLab.com' do
    let(:gitlab_com_except_jh?) { false }

    it 'schedules a new batched migration' do
      reversible_migration do |migration|
        migration.before -> {
          expect(batched_migration).not_to have_scheduled_batched_migration
        }

        migration.after -> {
          expect(batched_migration).to have_scheduled_batched_migration(
            gitlab_schema: :gitlab_ci,
            table_name: :ci_runner_machines,
            column_name: :runner_id,
            interval: described_class::DELAY_INTERVAL,
            batch_size: described_class::BATCH_SIZE,
            batch_class_name: 'LooseIndexScanBatchingStrategy',
            sub_batch_size: described_class::SUB_BATCH_SIZE
          )
        }
      end
    end
  end
end
