# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe QueueUpdateDelayedProjectRemovalToNullForUserNamespace, feature_category: :subgroups do
  let(:migration) { described_class::MIGRATION }

  describe '#up' do
    it 'schedules background jobs for each batch of namespace settings' do
      migrate!

      expect(migration).to(
        have_scheduled_batched_migration(
          table_name: :namespace_settings,
          column_name: :namespace_id,
          interval: described_class::INTERVAL,
          batch_size: described_class::BATCH_SIZE
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
