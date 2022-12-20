# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe CleanupAttentionRequestRelatedSystemNotes, :migration, feature_category: :team_planning do
  let(:notes) { table(:notes) }
  let(:system_note_metadata) { table(:system_note_metadata) }

  it 'removes all notes with attention request related system_note_metadata' do
    notes.create!(id: 1, note: 'Attention request note', noteable_type: 'MergeRequest')
    notes.create!(id: 2, note: 'Attention request remove note', noteable_type: 'MergeRequest')
    notes.create!(id: 3, note: 'MergeRequest note', noteable_type: 'MergeRequest')
    notes.create!(id: 4, note: 'Commit note', noteable_type: 'Commit')
    system_note_metadata.create!(id: 11, action: 'attention_requested', note_id: 1)
    system_note_metadata.create!(id: 22, action: 'attention_request_removed', note_id: 2)
    system_note_metadata.create!(id: 33, action: 'merged', note_id: 3)

    expect { migrate! }.to change(notes, :count).by(-2)

    expect(system_note_metadata.where(action: %w[attention_requested attention_request_removed]).size).to eq(0)
    expect(notes.where(noteable_type: 'MergeRequest').size).to eq(1)
    expect(notes.where(noteable_type: 'Commit').size).to eq(1)
    expect(system_note_metadata.where(action: 'merged').size).to eq(1)
  end
end
