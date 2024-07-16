# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe FinalizeBackfillEpicDatesToWorkItemDatesSources, feature_category: :database, migration_version: 20240702092809 do
  describe '#up' do
    it 'ensures the migration is completed for self-managed instances' do
      # enqueue the migration
      QueueBackfillEpicDatesToWorkItemDatesSources.new.up

      migration = Gitlab::Database::BackgroundMigration::BatchedMigration.where(
        job_class_name: 'BackfillEpicDatesToWorkItemDatesSources',
        table_name: 'epics'
      ).first

      expect(migration.status).not_to eq(6) # finalized

      migrate!

      expect(migration.reload.status).to eq(6)
      QueueBackfillEpicDatesToWorkItemDatesSources.new.down
    end
  end
end
