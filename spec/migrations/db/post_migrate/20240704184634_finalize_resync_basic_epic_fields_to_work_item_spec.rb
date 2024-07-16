# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe FinalizeResyncBasicEpicFieldsToWorkItem, feature_category: :database, migration_version: 20240704184634 do
  describe '#up' do
    it 'ensures the migration is completed for self-managed instances' do
      QueueResyncBasicEpicFieldsToWorkItem.new.up

      migration = Gitlab::Database::BackgroundMigration::BatchedMigration.where(
        job_class_name: 'ResyncBasicEpicFieldsToWorkItem',
        table_name: 'epics'
      ).first

      expect(migration.status).not_to eq(6)

      migrate!

      expect(migration.reload.status).to eq(6)
      QueueResyncBasicEpicFieldsToWorkItem.new.down
    end
  end
end
