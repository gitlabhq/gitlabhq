# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillInternalOnNotes, :migration, schema: 20211202041233 do
  let(:notes_table) { table(:notes) }

  let!(:confidential_note) { notes_table.create!(id: 1, confidential: true, internal: false) }
  let!(:non_confidential_note) { notes_table.create!(id: 2, confidential: false, internal: false) }

  describe '#perform' do
    subject(:perform) do
      described_class.new(
        start_id: 1,
        end_id: 2,
        batch_table: :notes,
        batch_column: :id,
        sub_batch_size: 1,
        pause_ms: 0,
        connection: ApplicationRecord.connection
      ).perform
    end

    it 'backfills internal column on notes when confidential' do
      expect { perform }
        .to change { confidential_note.reload.internal }.from(false).to(true)
        .and not_change { non_confidential_note.reload.internal }
    end
  end
end
