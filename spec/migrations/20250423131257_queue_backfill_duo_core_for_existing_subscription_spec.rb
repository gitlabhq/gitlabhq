# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe QueueBackfillDuoCoreForExistingSubscription, migration: :gitlab_main, feature_category: :subscription_management do
  let!(:batched_migration) { described_class::MIGRATION }

  before do
    allow(Gitlab).to receive(:com_except_jh?).and_return(gitlab_com_except_jh?)
  end

  context 'when it is not on GitLab.com' do
    let(:gitlab_com_except_jh?) { false }

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

  context 'when it is on GitLab.com' do
    let(:gitlab_com_except_jh?) { true }

    it 'schedules a new batched migration' do
      reversible_migration do |migration|
        migration.before -> {
          expect(batched_migration).not_to have_scheduled_batched_migration
        }

        migration.after -> {
          expect(batched_migration).to have_scheduled_batched_migration(
            gitlab_schema: :gitlab_main,
            table_name: :gitlab_subscriptions,
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
