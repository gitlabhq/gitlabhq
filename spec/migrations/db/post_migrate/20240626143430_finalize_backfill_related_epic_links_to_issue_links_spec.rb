# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe FinalizeBackfillRelatedEpicLinksToIssueLinks, feature_category: :database, migration_version: 20240626143430 do
  describe '#up' do
    it 'ensures the migration is completed for self-managed instances' do
      # enqueue the migration
      QueueBackfillRelatedEpicLinksToIssueLinks.new.up

      migration = Gitlab::Database::BackgroundMigration::BatchedMigration.where(
        job_class_name: 'BackfillRelatedEpicLinksToIssueLinks',
        table_name: 'related_epic_links'
      ).first

      expect(migration.status).not_to eq(6) # finalized

      migrate!

      expect(migration.reload.status).to eq(6)
      QueueBackfillRelatedEpicLinksToIssueLinks.new.down
    end
  end
end
