# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe BackfillProjectImportLevel, feature_category: :importers do
  let!(:batched_migration) { described_class::MIGRATION }

  describe '#up' do
    it 'schedules background jobs for each batch of namespaces' do
      migrate!

      expect(batched_migration).to have_scheduled_batched_migration(
        table_name: :namespaces,
        column_name: :id,
        interval: described_class::INTERVAL
      )
    end
  end

  describe '#down' do
    it 'deletes all batched migration records' do
      migrate!
      schema_migrate_down!

      expect(batched_migration).not_to have_scheduled_batched_migration
    end
  end
end
