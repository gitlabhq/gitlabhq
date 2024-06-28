# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe FinalizeBackfillEpicBasicFieldsToWorkItemRecordCorrected, feature_category: :database, migration_version: 20240510113339 do
  describe '#up' do
    let(:migration_arguments) do
      {
        job_class_name: 'BackfillEpicBasicFieldsToWorkItemRecord',
        table_name: 'epics',
        column_name: 'id',
        job_arguments: [nil],
        finalize: true
      }
    end

    it 'ensures the migration is completed for self-managed instances' do
      # enqueue the migration
      QueueBackfillEpicBasicFieldsToWorkItemRecord.new.up

      migration = Gitlab::Database::BackgroundMigration::BatchedMigration.where(
        job_class_name: 'BackfillEpicBasicFieldsToWorkItemRecord',
        table_name: 'epics'
      ).first

      expect(migration.status).not_to eq(6) # finalized

      migrate!

      expect(migration.reload.status).to eq(6)
      QueueBackfillEpicBasicFieldsToWorkItemRecord.new.down
    end
  end
end
