# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe FinalizeBackfillEpicIssuesIntoWorkItemParentLinks, feature_category: :database, migration_version: 20240701182755 do
  describe '#up' do
    it 'ensures the migration is completed for self-managed instances' do
      # enqueue the migration
      QueueBackfillEpicIssuesIntoWorkItemParentLinks.new.up

      migration = Gitlab::Database::BackgroundMigration::BatchedMigration.where(
        job_class_name: 'BackfillEpicIssuesIntoWorkItemParentLinks',
        table_name: 'epic_issues'
      ).first

      expect(migration.status).not_to eq(6) # finalized

      migrate!

      expect(migration.reload.status).to eq(6)
      QueueBackfillEpicIssuesIntoWorkItemParentLinks.new.down
    end
  end
end
