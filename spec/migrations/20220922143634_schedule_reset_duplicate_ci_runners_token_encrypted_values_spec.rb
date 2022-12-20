# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe ScheduleResetDuplicateCiRunnersTokenEncryptedValues,
  feature_category: :runner_fleet,
  migration: :gitlab_ci do
  let(:migration) { described_class::MIGRATION }

  describe '#up' do
    it 'schedules background jobs for each batch of runners' do
      migrate!

      expect(migration).to(
        have_scheduled_batched_migration(
          gitlab_schema: :gitlab_ci,
          table_name: :ci_runners,
          column_name: :id,
          interval: described_class::DELAY_INTERVAL,
          batch_size: described_class::BATCH_SIZE,
          max_batch_size: described_class::MAX_BATCH_SIZE,
          sub_batch_size: described_class::SUB_BATCH_SIZE
        )
      )
    end
  end

  describe '#down' do
    it 'deletes all batched migration records' do
      migrate!
      schema_migrate_down!

      expect(migration).not_to have_scheduled_batched_migration
    end
  end
end
