# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillNoteDiscussionId, feature_category: :importers do
  let(:migration) { described_class.new }
  let(:notes_table) { table(:notes) }
  let(:existing_discussion_id) { Digest::SHA1.hexdigest('test') }

  before do
    notes_table.create!(id: 1, noteable_type: 'Issue', noteable_id: 2, discussion_id: existing_discussion_id)
    notes_table.create!(id: 2, noteable_type: 'Issue', noteable_id: 1, discussion_id: nil)
    notes_table.create!(id: 3, noteable_type: 'MergeRequest', noteable_id: 1, discussion_id: nil)
    notes_table.create!(id: 4, noteable_type: 'Commit', commit_id: RepoHelpers.sample_commit.id, discussion_id: nil)
    notes_table.create!(id: 5, noteable_type: 'Issue', noteable_id: 2, discussion_id: nil)
    notes_table.create!(id: 6, noteable_type: 'MergeRequest', noteable_id: 2, discussion_id: nil)
  end

  it 'updates records in the specified batch', :aggregate_failures do
    migration.perform(1, 5)

    expect(notes_table.where(discussion_id: nil).count).to eq(1)

    expect(notes_table.find(1).discussion_id).to eq(existing_discussion_id)
    notes_table.where(id: 2..5).find_each do |n|
      expect(n.discussion_id).to match(/\A[0-9a-f]{40}\z/)
    end
  end
end
