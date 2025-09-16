# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe QueueBackfillFinishOnboardingForGroupSaml, migration: :gitlab_main_org, feature_category: :onboarding do
  let!(:batched_migration) { described_class::MIGRATION }

  it 'schedules a new batched migration' do
    reversible_migration do |migration|
      migration.before -> {
        expect(batched_migration).not_to have_scheduled_batched_migration
      }

      attributes = {
        table_name: :identities,
        column_name: :id,
        interval: described_class::DELAY_INTERVAL,
        batch_size: described_class::BATCH_SIZE,
        sub_batch_size: described_class::SUB_BATCH_SIZE,
        max_batch_size: described_class::MAX_BATCH_SIZE
      }

      migration.after -> {
        expect(batched_migration).to have_scheduled_batched_migration(attributes)
      }
    end
  end
end
