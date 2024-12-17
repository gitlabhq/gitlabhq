# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe RequeueBackfillFreeSharedRunnersMinutesLimit, feature_category: :consumables_cost_management do
  let!(:batched_migration) { described_class::MIGRATION }

  it 'does not schedule the background job when Gitlab.com_except_jh? is false' do
    allow(Gitlab).to receive_messages(dev_or_test_env?: false, com_except_jh?: false)

    reversible_migration do |migration|
      migration.before -> {
        expect(batched_migration).not_to have_scheduled_batched_migration
      }

      migration.after -> {
        expect(batched_migration).not_to have_scheduled_batched_migration
      }
    end
  end

  it 'schedules a new batched migration when Gitlab.com_except_jh? is true' do
    allow(Gitlab).to receive_messages(dev_or_test_env?: true, com_except_jh?: true)

    reversible_migration do |migration|
      migration.before -> {
        expect(batched_migration).not_to have_scheduled_batched_migration
      }

      migration.after -> {
        expect(batched_migration).to have_scheduled_batched_migration(
          table_name: :namespaces,
          column_name: :id,
          interval: described_class::DELAY_INTERVAL,
          batch_size: described_class::BATCH_SIZE,
          sub_batch_size: described_class::SUB_BATCH_SIZE,
          gitlab_schema: :gitlab_main
        )
      }
    end
  end
end
