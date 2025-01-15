# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::Importer::Events::ChangedReviewer, feature_category: :importers do
  subject(:importer) { described_class.new(project, client) }

  let_it_be(:project) { create(:project, :repository, :with_import_url) }
  let_it_be_with_reload(:requested_reviewer) { create(:user) }
  let_it_be(:review_requester) { create(:user) }
  let_it_be(:issuable) { create(:merge_request, source_project: project, target_project: project) }

  let(:client) { instance_double('Gitlab::GithubImport::Client') }

  let(:issue_event) do
    Gitlab::GithubImport::Representation::IssueEvent.from_json_hash(
      'id' => 6501124486,
      'actor' => { 'id' => review_requester.id, 'login' => review_requester.username },
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
      updated_at: issue_event.created_at,
      imported_from: 'github'
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

    context 'when requested_reviewer is nil' do
      before do
        requested_reviewer.username = nil
      end

      it 'references `@ghost`' do
        importer.execute(issue_event)

        expect(issuable.notes.last.note).to end_with('`@ghost`')
      end
    end
  end

  shared_examples 'process review_requested & review_request_removed MR events' do
    context 'when importing a review_requested event' do
      let(:event_type) { 'review_requested' }
      let(:expected_note_attrs) { note_attrs.merge(note: "requested review from `@#{requested_reviewer.username}`") }

      it_behaves_like 'create expected notes'
    end

    context 'when importing a review_request_removed event' do
      let(:event_type) { 'review_request_removed' }
      let(:expected_note_attrs) do
        note_attrs.merge(note: "removed review request for `@#{requested_reviewer.username}`")
      end

      it_behaves_like 'create expected notes'
    end
  end

  shared_examples 'push placeholder reference' do
    let(:event_type) { 'changed' }
    it 'pushes the reference' do
      expect(subject)
      .to receive(:push_with_record)
      .with(
        an_instance_of(Note),
        :author_id,
        review_requester.id,
        an_instance_of(Gitlab::Import::SourceUserMapper)
      )

      importer.execute(issue_event)
    end
  end

  shared_examples 'do not push placeholder reference' do
    let(:event_type) { 'changed' }
    it 'does not push any reference' do
      expect(subject)
      .not_to receive(:push_with_record)

      importer.execute(issue_event)
    end
  end

  describe '#execute' do
    before do
      allow_next_instance_of(Gitlab::GithubImport::IssuableFinder) do |finder|
        allow(finder).to receive(:database_id).and_return(issuable.id)
      end
    end

    context 'when user mapping is enabled' do
      let_it_be(:source_user_requester) do
        create(
          :import_source_user,
          placeholder_user_id: review_requester.id,
          source_user_identifier: review_requester.id,
          source_username: review_requester.username,
          source_hostname: project.import_url,
          namespace_id: project.root_ancestor.id
        )
      end

      let_it_be(:source_user_requested) do
        create(
          :import_source_user,
          placeholder_user_id: requested_reviewer.id,
          source_user_identifier: requested_reviewer.id,
          source_username: requested_reviewer.username,
          source_hostname: project.import_url,
          namespace_id: project.root_ancestor.id
        )
      end

      let_it_be(:merge_request_reviewer) do
        create(
          :merge_request_reviewer,
          user_id: requested_reviewer.id,
          merge_request_id: issuable.id
        )
      end

      before do
        project.build_or_assign_import_data(data: { user_contribution_mapping_enabled: true })
      end

      it_behaves_like 'process review_requested & review_request_removed MR events'
      it_behaves_like 'push placeholder reference'
    end

    context 'when user mapping is disabled' do
      before do
        project.build_or_assign_import_data(data: { user_contribution_mapping_enabled: false })
        allow_next_instance_of(Gitlab::GithubImport::UserFinder) do |finder|
          allow(finder).to receive(:find).with(requested_reviewer.id, requested_reviewer.username)
            .and_return(requested_reviewer.id)
          allow(finder).to receive(:find).with(review_requester.id, review_requester.username)
            .and_return(review_requester.id)
        end
      end

      it_behaves_like 'process review_requested & review_request_removed MR events'
      it_behaves_like 'do not push placeholder reference'
    end
  end
end
