# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe CleanUpNoteableIdForNotesOnCommits do
  let(:notes) { table(:notes) }

  before do
    notes.create!(noteable_type: 'Commit', commit_id: '3d0a182204cece4857f81c6462720e0ad1af39c9', noteable_id: 3, note: 'Test')
    notes.create!(noteable_type: 'Commit', commit_id: '3d0a182204cece4857f81c6462720e0ad1af39c9', noteable_id: 3, note: 'Test')
    notes.create!(noteable_type: 'Commit', commit_id: '3d0a182204cece4857f81c6462720e0ad1af39c9', noteable_id: 3, note: 'Test')

    notes.create!(noteable_type: 'Issue', noteable_id: 1, note: 'Test')
    notes.create!(noteable_type: 'MergeRequest', noteable_id: 1, note: 'Test')
    notes.create!(noteable_type: 'Snippet', noteable_id: 1, note: 'Test')
  end

  it 'clears noteable_id for notes on commits' do
    expect { migrate! }.to change { dirty_notes_on_commits.count }.from(3).to(0)
  end

  it 'does not clear noteable_id for other notes' do
    expect { migrate! }.not_to change { other_notes.count }
  end

  def dirty_notes_on_commits
    notes.where(noteable_type: 'Commit').where.not(noteable_id: nil)
  end

  def other_notes
    notes.where("noteable_type != 'Commit' AND noteable_id IS NOT NULL")
  end
end
