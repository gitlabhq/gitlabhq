# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe FinalizeDeletePackagesComposerCacheFileRecords, feature_category: :package_registry, migration_version: 20240816092254 do
  describe '#up' do
    it 'ensures the migration is completed for self-managed instances' do
      QueueDeletePackagesComposerCacheFileRecords.new.up

      migration = Gitlab::Database::BackgroundMigration::BatchedMigration.where(
        job_class_name: 'DeletePackagesComposerCacheFileRecords',
        table_name: 'packages_composer_cache_files'
      ).first

      expect(migration.status).not_to eq(6) # finalized

      migrate!

      expect(migration.reload.status).to eq(6)
      QueueDeletePackagesComposerCacheFileRecords.new.down
    end
  end
end
