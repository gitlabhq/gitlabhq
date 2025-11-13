# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::Importer::Events::ChangedReviewer, :clean_gitlab_redis_shared_state, feature_category: :importers do
  include Import::UserMappingHelper

  subject(:importer) { described_class.new(project, client) }

  let_it_be_with_reload(:project) do
    create(
      :project, :in_group, :github_import,
      :import_user_mapping_enabled
    )
  end

  let_it_be_with_reload(:requested_reviewer) { create(:user) }
  let_it_be(:review_requester) { create(:user) }
  let_it_be(:issuable) { create(:merge_request, source_project: project, target_project: project) }

  let(:client) { instance_double('Gitlab::GithubImport::Client') }
  let(:github_review_requester) { { 'id' => 1000, 'login' => 'github_author' } }
  let(:github_requested_reviewer) { { 'id' => 1001, 'login' => 'another_github_user' } }

  let(:issue_event) do
    Gitlab::GithubImport::Representation::IssueEvent.from_json_hash(
      'id' => 6501124486,
      'actor' => github_review_requester,
      'event' => event_type,
      'commit_id' => nil,
      'created_at' => '2022-04-26 18:30:53 UTC',
      'review_requester' => github_review_requester,
      'requested_reviewer' => github_requested_reviewer,
      'issue' => { 'number' => issuable.iid, pull_request: issuable.is_a?(MergeRequest) }
    )
  end

  let(:cached_references) { placeholder_user_references(Import::SOURCE_GITHUB, project.import_state.id) }

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

    context 'when requested reviewer is not found on GitHub' do
      let(:github_requested_reviewer) { { 'id' => nil, 'login' => nil } }

      it 'references `@ghost`' do
        importer.execute(issue_event)

        expect(issuable.notes.last.note).to end_with('`@ghost`')
      end
    end
  end

  shared_examples 'process review_requested & review_request_removed MR events' do
    context 'when importing a review_requested event' do
      let(:event_type) { 'review_requested' }
      let(:expected_note_attrs) do
        note_attrs.merge(note: "requested review from `@#{github_requested_reviewer['login']}`")
      end

      it_behaves_like 'create expected notes'
    end

    context 'when importing a review_request_removed event' do
      let(:event_type) { 'review_request_removed' }
      let(:expected_note_attrs) do
        note_attrs.merge(note: "removed review request for `@#{github_requested_reviewer['login']}`")
      end

      it_behaves_like 'create expected notes'
    end
  end

  shared_examples 'push placeholder reference' do
    let(:event_type) { 'changed' }

    it 'pushes the reference' do
      importer.execute(issue_event)

      expect(cached_references).to match_array([
        ['Note', an_instance_of(Integer), 'author_id', source_user.id]
      ])
    end
  end

  shared_examples 'do not push placeholder reference' do
    let(:event_type) { 'changed' }

    it 'does not push any reference' do
      importer.execute(issue_event)

      expect(cached_references).to be_empty
    end
  end

  describe '#execute' do
    before do
      allow_next_instance_of(Gitlab::GithubImport::IssuableFinder) do |finder|
        allow(finder).to receive(:database_id).and_return(issuable.id)
      end
    end

    context 'when user mapping is enabled' do
      let_it_be(:source_user) { generate_source_user(project, 1000) }
      let_it_be(:mapped_user_id) { source_user.mapped_user_id }

      let(:note_attrs) do
        {
          noteable_id: issuable.id,
          noteable_type: issuable.class.name,
          project_id: project.id,
          author_id: mapped_user_id,
          system: true,
          created_at: issue_event.created_at,
          updated_at: issue_event.created_at,
          imported_from: 'github'
        }.stringify_keys
      end

      let_it_be(:merge_request_reviewer) do
        create(
          :merge_request_reviewer,
          user_id: mapped_user_id,
          merge_request_id: issuable.id
        )
      end

      it_behaves_like 'process review_requested & review_request_removed MR events'
      it_behaves_like 'push placeholder reference'

      context 'when importing into a personal namespace' do
        let_it_be(:user_namespace) { create(:namespace) }
        let(:mapped_user_id) { user_namespace.owner.id }

        before_all do
          project.update!(namespace: user_namespace)
        end

        it_behaves_like 'process review_requested & review_request_removed MR events'
        it_behaves_like 'do not push placeholder reference'
      end
    end

    context 'when user mapping is disabled' do
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

      before do
        project.build_or_assign_import_data(data: { user_contribution_mapping_enabled: false }).save!
        allow_next_instance_of(Gitlab::GithubImport::UserFinder) do |finder|
          allow(finder).to receive(:find).with(github_review_requester['id'], github_review_requester['login'])
            .and_return(review_requester.id)
          allow(finder).to receive(:find).with(github_requested_reviewer['id'], github_requested_reviewer['login'])
            .and_return(requested_reviewer.id)
        end
      end

      it_behaves_like 'process review_requested & review_request_removed MR events'
      it_behaves_like 'do not push placeholder reference'
    end
  end
end
