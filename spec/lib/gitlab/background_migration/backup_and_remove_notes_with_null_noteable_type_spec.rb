# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackupAndRemoveNotesWithNullNoteableType,
  feature_category: :team_planning,
  schema: 20240524152952 do
  before(:all) do
    # This migration will not work if a sec database is configured. It should be finalized and removed prior to
    # sec db rollout.
    # Consult https://gitlab.com/gitlab-org/gitlab/-/merge_requests/171707 for more info.
    skip_if_multiple_databases_are_setup(:sec)
  end

  let(:notes) { table(:notes) }
  let(:temp_notes_backup) { table(:temp_notes_backup) }
  let(:migration_args) do
    {
      start_id: notes.minimum(:id),
      end_id: notes.maximum(:id),
      batch_table: :notes,
      batch_column: :id,
      sub_batch_size: 1,
      pause_ms: 0,
      connection: ApplicationRecord.connection
    }
  end

  it 'backs up and removes orphaned notes records' do
    # Note:
    # This background migration attempts to remove the existing `notes` records with NULL noteable_type.
    # The removed records will be stored in the `temp_notes_back` table to be safe.
    #
    # The `notes` table received a new check constraint to prevent `null` noteable_type in an earlier migration.
    # To create records with NULL noteable_type, we need to drop the constraint.
    # (`schema:` cannot be used because the migration requires the `temp_notes_back` table to be present.)
    #
    # To keep the test database's schema valid, the dropping will be performing inside a transaction.
    ApplicationRecord.connection.transaction do
      ApplicationRecord.connection.execute("ALTER TABLE notes DROP CONSTRAINT check_1244cbd7d0;")

      notes.create!(id: 1, noteable_type: 'a')
      notes.create!(id: 2, note: 'orphan 1', noteable_type: nil)
      notes.create!(id: 3, noteable_type: 'b')
      notes.create!(id: 4, note: 'orphan 2', noteable_type: nil)
      notes.create!(id: 5, noteable_type: 'c')

      expect { described_class.new(**migration_args).perform }
        .to change { notes.count }
        .by(-2)
        .and change { notes.where(noteable_type: nil).count }
        .by(-2)
        .and change { temp_notes_backup.count }
        .by(2)

      expect(temp_notes_backup.first.note).to eq('orphan 1')
      expect(temp_notes_backup.last.note).to eq('orphan 2')

      ApplicationRecord.connection.execute("ABORT")
    end
  end
end
