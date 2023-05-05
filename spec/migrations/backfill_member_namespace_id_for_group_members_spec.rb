# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe BackfillMemberNamespaceIdForGroupMembers, feature_category: :subgroups do
  let!(:migration) { described_class::MIGRATION }

  describe '#up' do
    it 'schedules background jobs for each batch of group members' do
      migrate!

      expect(migration).to have_scheduled_batched_migration(
        table_name: :members,
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
