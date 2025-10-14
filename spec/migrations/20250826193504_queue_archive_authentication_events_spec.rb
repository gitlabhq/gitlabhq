# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe QueueArchiveAuthenticationEvents, migration: :gitlab_main, feature_category: :system_access do
  let!(:batched_migration) { described_class::MIGRATION }

  context "when running on GitLab.com", :saas do
    it 'schedules a new batched migration' do
      reversible_migration do |migration|
        migration.before -> {
          expect(batched_migration).not_to have_scheduled_batched_migration
        }

        migration.after -> {
          expect(batched_migration).to have_scheduled_batched_migration(
            gitlab_schema: :gitlab_main,
            table_name: :authentication_events,
            column_name: :id,
            interval: described_class::DELAY_INTERVAL,
            batch_size: described_class::BATCH_SIZE,
            sub_batch_size: described_class::SUB_BATCH_SIZE
          )
        }
      end
    end
  end

  context "when not running on GitLab.com" do
    it "does not schedule a new batched migration" do
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
end
