# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::Importer::Events::Renamed do
  subject(:importer) { described_class.new(project, user.id) }

  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user) { create(:user) }

  let(:issue) { create(:issue, project: project) }

  let(:issue_event) do
    Gitlab::GithubImport::Representation::IssueEvent.from_json_hash(
      'id' => 6501124486,
      'actor' => { 'id' => 4, 'login' => 'alice' },
      'event' => 'renamed',
      'commit_id' => nil,
      'created_at' => '2022-04-26 18:30:53 UTC',
      'old_title' => 'old title',
      'new_title' => 'new title',
      'issue_db_id' => issue.id
    )
  end

  let(:expected_note_attrs) do
    {
      noteable_id: issue.id,
      noteable_type: Issue.name,
      project_id: project.id,
      author_id: user.id,
      note: "changed title from **{-old-} title** to **{+new+} title**",
      system: true,
      created_at: issue_event.created_at,
      updated_at: issue_event.created_at
    }.stringify_keys
  end

  let(:expected_system_note_metadata_attrs) do
    {
      action: "title",
      created_at: issue_event.created_at,
      updated_at: issue_event.created_at
    }.stringify_keys
  end

  describe '#execute' do
    it 'creates expected note' do
      expect { importer.execute(issue_event) }.to change { issue.notes.count }
        .from(0).to(1)

      expect(issue.notes.last)
        .to have_attributes(expected_note_attrs)
    end

    it 'creates expected system note metadata' do
      expect { importer.execute(issue_event) }.to change { SystemNoteMetadata.count }
          .from(0).to(1)

      expect(SystemNoteMetadata.last)
        .to have_attributes(
          expected_system_note_metadata_attrs.merge(
            note_id: Note.last.id
          )
        )
    end
  end
end
