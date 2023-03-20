# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe UpdateIssuesInternalIdScope, feature_category: :team_planning do
  describe '#up' do
    it 'schedules background migration' do
      migrate!

      expect(described_class::MIGRATION).to have_scheduled_batched_migration(
        table_name: :internal_ids,
        column_name: :id,
        interval: described_class::INTERVAL)
    end
  end

  describe '#down' do
    it 'does not schedule background migration' do
      schema_migrate_down!

      expect(described_class::MIGRATION).not_to have_scheduled_batched_migration(
        table_name: :internal_ids,
        column_name: :id,
        interval: described_class::INTERVAL)
    end
  end
end
