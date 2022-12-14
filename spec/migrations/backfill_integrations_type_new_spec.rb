# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe BackfillIntegrationsTypeNew, feature_category: :integrations do
  let!(:migration) { described_class::MIGRATION }
  let!(:integrations) { table(:integrations) }

  before do
    integrations.create!(id: 1)
    integrations.create!(id: 2)
    integrations.create!(id: 3)
    integrations.create!(id: 4)
    integrations.create!(id: 5)
  end

  describe '#up' do
    it 'schedules background jobs for each batch of integrations' do
      migrate!

      expect(migration).to have_scheduled_batched_migration(
        table_name: :integrations,
        column_name: :id,
        interval: described_class::INTERVAL
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
