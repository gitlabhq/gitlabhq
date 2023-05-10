# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe RescheduleEvidencesHandlingUnicode, :migration, feature_category: :vulnerability_management do
  let(:migration) { described_class::MIGRATION }

  describe '#up' do
    it 'schedules a batched background migration' do
      migrate!

      expect(migration).to have_scheduled_batched_migration(
        table_name: :vulnerability_occurrences,
        column_name: :id,
        interval: described_class::DELAY_INTERVAL,
        batch_size: described_class::BATCH_SIZE,
        sub_batch_size: described_class::SUB_BATCH_SIZE
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
