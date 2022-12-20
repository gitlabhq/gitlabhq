# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe CleanupOrphanedRoutes, :migration, feature_category: :projects do
  let(:migration) { described_class::MIGRATION }

  describe '#up' do
    it 'schedules background jobs' do
      migrate!

      expect(migration).to have_scheduled_batched_migration(
        table_name: :routes,
        column_name: :id,
        interval: described_class::DELAY_INTERVAL,
        gitlab_schema: :gitlab_main
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
