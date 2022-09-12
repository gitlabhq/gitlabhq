# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::Importer::Events::ChangedReviewer do
  subject(:importer) { described_class.new(project, client) }

  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:requested_reviewer) { create(:user) }
  let_it_be(:review_requester) { create(:user) }

  let(:client) { instance_double('Gitlab::GithubImport::Client') }
  let(:issuable) { create(:merge_request, source_project: project, target_project: project) }

  let(:issue_event) do
    Gitlab::GithubImport::Representation::IssueEvent.from_json_hash(
      'id' => 6501124486,
      'actor' => { 'id' => 4, 'login' => 'alice' },
      'event' => event_type,
      'commit_id' => nil,
      'created_at' => '2022-04-26 18:30:53 UTC',
      'review_requester' => { 'id' => review_requester.id, 'login' => review_requester.username },
      'requested_reviewer' => { 'id' => requested_reviewer.id, 'login' => requested_reviewer.username },
      'issue' => { 'number' => issuable.iid, pull_request: issuable.is_a?(MergeRequest) }
    )
  end

  let(:note_attrs) do
    {
      noteable_id: issuable.id,
      noteable_type: issuable.class.name,
      project_id: project.id,
      author_id: review_requester.id,
      system: true,
      created_at: issue_event.created_at,
      updated_at: issue_event.created_at
    }.stringify_keys
  end

  let(:expected_system_note_metadata_attrs) do
    {
      action: 'reviewer',
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
      expect { importer.execute(issue_event) }.to change(SystemNoteMetadata, :count)
        .from(0).to(1)

      expect(SystemNoteMetadata.last)
        .to have_attributes(
          expected_system_note_metadata_attrs.merge(
            note_id: Note.last.id
          )
        )
    end
  end

  shared_examples 'process review_requested & review_request_removed MR events' do
    context 'when importing a review_requested event' do
      let(:event_type) { 'review_requested' }
      let(:expected_note_attrs) { note_attrs.merge(note: "requested review from @#{requested_reviewer.username}") }

      it_behaves_like 'create expected notes'
    end

    context 'when importing a review_request_removed event' do
      let(:event_type) { 'review_request_removed' }
      let(:expected_note_attrs) { note_attrs.merge(note: "removed review request for @#{requested_reviewer.username}") }

      it_behaves_like 'create expected notes'
    end
  end

  describe '#execute' do
    before do
      allow_next_instance_of(Gitlab::GithubImport::IssuableFinder) do |finder|
        allow(finder).to receive(:database_id).and_return(issuable.id)
      end
      allow_next_instance_of(Gitlab::GithubImport::UserFinder) do |finder|
        allow(finder).to receive(:find).with(requested_reviewer.id, requested_reviewer.username)
          .and_return(requested_reviewer.id)
        allow(finder).to receive(:find).with(review_requester.id, review_requester.username)
          .and_return(review_requester.id)
      end
    end

    it_behaves_like 'process review_requested & review_request_removed MR events'
  end
end
