# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe QueueBackfillGitlabSubscriptionsHostedPlanNameUid, migration: :gitlab_main_org,
  feature_category: :subscription_management do
  let!(:batched_migration) { described_class::MIGRATION }

  it 'schedules a new batched migration' do
    reversible_migration do |migration|
      migration.before -> {
        expect(batched_migration).not_to have_scheduled_batched_migration
      }

      migration.after -> {
        expect(batched_migration).to have_scheduled_batched_migration(
          table_name: :gitlab_subscriptions,
          column_name: :id,
          batch_size: described_class::BATCH_SIZE,
          sub_batch_size: described_class::SUB_BATCH_SIZE
        )
      }
    end
  end
end
