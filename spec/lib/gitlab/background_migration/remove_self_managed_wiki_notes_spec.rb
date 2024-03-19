# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::RemoveSelfManagedWikiNotes, :migration, schema: 20230616082958 do
  let(:notes) { table(:notes) }

  subject(:perform_migration) do
    described_class.new(
      start_id: 1,
      end_id: 30,
      batch_table: :notes,
      batch_column: :id,
      sub_batch_size: 2,
      pause_ms: 0,
      connection: ActiveRecord::Base.connection
    ).perform
  end

  it 'removes all wiki notes' do
    notes.create!(id: 2, note: 'Commit note', noteable_type: 'Commit')
    notes.create!(id: 10, note: 'Issue note', noteable_type: 'Issue')
    notes.create!(id: 20, note: 'Wiki note', noteable_type: 'Wiki')
    notes.create!(id: 30, note: 'MergeRequest note', noteable_type: 'MergeRequest')

    expect(notes.where(noteable_type: 'Wiki').size).to eq(1)

    expect { perform_migration }.to change(notes, :count).by(-1)

    expect(notes.where(noteable_type: 'Wiki').size).to eq(0)
  end
end
