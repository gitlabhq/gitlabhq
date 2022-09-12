# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::Importer::Events::ChangedAssignee do
  subject(:importer) { described_class.new(project, client) }

  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:author) { create(:user) }
  let_it_be(:assignee) { create(:user) }

  let(:client) { instance_double('Gitlab::GithubImport::Client') }
  let(:issuable) { create(:issue, project: project) }

  let(:issue_event) do
    Gitlab::GithubImport::Representation::IssueEvent.from_json_hash(
      'id' => 6501124486,
      'actor' => { 'id' => author.id, 'login' => author.username },
      'event' => event_type,
      'commit_id' => nil,
      'created_at' => '2022-04-26 18:30:53 UTC',
      'assignee' => { 'id' => assignee.id, 'login' => assignee.username },
      'issue' => { 'number' => issuable.iid, pull_request: issuable.is_a?(MergeRequest) }
    )
  end

  let(:note_attrs) do
    {
      noteable_id: issuable.id,
      noteable_type: issuable.class.name,
      project_id: project.id,
      author_id: author.id,
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

  shared_examples 'create expected notes' do
    it 'creates expected note' do
      expect { importer.execute(issue_event) }.to change { issuable.notes.count }
        .from(0).to(1)

      expect(issuable.notes.last)
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

  shared_examples 'process assigned & unassigned events' do
    context 'when importing an assigned event' do
      let(:event_type) { 'assigned' }
      let(:expected_note_attrs) { note_attrs.merge(note: "assigned to @#{assignee.username}") }

      it_behaves_like 'create expected notes'
    end

    context 'when importing an unassigned event' do
      let(:event_type) { 'unassigned' }
      let(:expected_note_attrs) { note_attrs.merge(note: "unassigned @#{assignee.username}") }

      it_behaves_like 'create expected notes'
    end
  end

  describe '#execute' do
    before do
      allow_next_instance_of(Gitlab::GithubImport::IssuableFinder) do |finder|
        allow(finder).to receive(:database_id).and_return(issuable.id)
      end
      allow_next_instance_of(Gitlab::GithubImport::UserFinder) do |finder|
        allow(finder).to receive(:find).with(author.id, author.username).and_return(author.id)
        allow(finder).to receive(:find).with(assignee.id, assignee.username).and_return(assignee.id)
      end
    end

    context 'with Issue' do
      it_behaves_like 'process assigned & unassigned events'
    end

    context 'with MergeRequest' do
      let(:issuable) { create(:merge_request, source_project: project, target_project: project) }

      it_behaves_like 'process assigned & unassigned events'
    end
  end
end
