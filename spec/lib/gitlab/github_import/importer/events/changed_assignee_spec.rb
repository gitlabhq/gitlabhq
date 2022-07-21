# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::Importer::Events::ChangedAssignee do
  subject(:importer) { described_class.new(project, user_finder) }

  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:assignee) { create(:user) }
  let_it_be(:assigner) { create(:user) }

  let(:client) { instance_double('Gitlab::GithubImport::Client') }
  let(:user_finder) { Gitlab::GithubImport::UserFinder.new(project, client) }
  let(:issue) { create(:issue, project: project) }

  let(:issue_event) do
    Gitlab::GithubImport::Representation::IssueEvent.from_json_hash(
      'id' => 6501124486,
      'actor' => { 'id' => 4, 'login' => 'alice' },
      'event' => event_type,
      'commit_id' => nil,
      'created_at' => '2022-04-26 18:30:53 UTC',
      'assigner' => { 'id' => assigner.id, 'login' => assigner.username },
      'assignee' => { 'id' => assignee.id, 'login' => assignee.username },
      'issue_db_id' => issue.id
    )
  end

  let(:note_attrs) do
    {
      noteable_id: issue.id,
      noteable_type: Issue.name,
      project_id: project.id,
      author_id: assigner.id,
      system: true,
      created_at: issue_event.created_at,
      updated_at: issue_event.created_at
    }.stringify_keys
  end

  let(:expected_system_note_metadata_attrs) do
    {
      action: "assignee",
      created_at: issue_event.created_at,
      updated_at: issue_event.created_at
    }.stringify_keys
  end

  shared_examples 'new note' do
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

  describe '#execute' do
    before do
      allow(user_finder).to receive(:find).with(assignee.id, assignee.username).and_return(assignee.id)
      allow(user_finder).to receive(:find).with(assigner.id, assigner.username).and_return(assigner.id)
    end

    context 'when importing an assigned event' do
      let(:event_type) { 'assigned' }
      let(:expected_note_attrs) { note_attrs.merge(note: "assigned to @#{assignee.username}") }

      it_behaves_like 'new note'
    end

    context 'when importing an unassigned event' do
      let(:event_type) { 'unassigned' }
      let(:expected_note_attrs) { note_attrs.merge(note: "unassigned @#{assigner.username}") }

      it_behaves_like 'new note'
    end
  end
end
