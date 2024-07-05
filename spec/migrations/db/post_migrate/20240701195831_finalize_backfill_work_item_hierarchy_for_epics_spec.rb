# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe FinalizeBackfillWorkItemHierarchyForEpics, feature_category: :database do
  describe '#up' do
    it 'ensures the migration is completed for self-managed instances' do
      # enqueue the migration
      QueueBackfillWorkItemHierarchyForEpics.new.up

      migration = Gitlab::Database::BackgroundMigration::BatchedMigration.where(
        job_class_name: 'BackfillWorkItemHierarchyForEpics',
        table_name: 'epics'
      ).first

      expect(migration.status).not_to eq(6) # finalized

      migrate!

      expect(migration.reload.status).to eq(6)
      QueueBackfillWorkItemHierarchyForEpics.new.down
    end
  end
end
