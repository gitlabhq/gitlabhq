# frozen_string_literal: true

require 'spec_helper'

RSpec.describe QueueUpdateClosedMergedMrs, feature_category: :code_review_workflow do
  let!(:batched_migration) { described_class::MIGRATION }

  context 'for Gitlab.com', :saas do
    it 'schedules a new batched migration' do
      reversible_migration do |migration|
        migration.before -> {
          expect(batched_migration).not_to have_scheduled_batched_migration
        }

        migration.after -> {
          expect(batched_migration).to have_scheduled_batched_migration(
            table_name: :merge_requests,
            column_name: :id,
            interval: described_class::DELAY_INTERVAL,
            batch_size: described_class::BATCH_SIZE,
            sub_batch_size: described_class::SUB_BATCH_SIZE
          )
        }
      end
    end
  end

  context "for anything not Gitlab.com" do
    it 'does not schedule a batched migration' do
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
