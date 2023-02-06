# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe NullifyCreatorIdOfOrphanedProjects, feature_category: :projects do
  let!(:migration) { described_class::MIGRATION }

  describe '#up' do
    it 'schedules background migration' do
      migrate!

      expect(migration).to have_scheduled_batched_migration(
        table_name: :projects,
        column_name: :id,
        interval: described_class::INTERVAL,
        batch_size: described_class::BATCH_SIZE,
        max_batch_size: described_class::MAX_BATCH_SIZE,
        sub_batch_size: described_class::SUB_BATCH_SIZE
      )
    end
  end

  describe '#down' do
    it 'removes scheduled background migrations' do
      migrate!
      schema_migrate_down!

      expect(migration).not_to have_scheduled_batched_migration
    end
  end
end
