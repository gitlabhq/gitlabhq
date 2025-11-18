# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::Importer::Events::Closed, :clean_gitlab_redis_shared_state, feature_category: :importers do
  include Import::UserMappingHelper

  subject(:importer) { described_class.new(project, client) }

  let_it_be_with_reload(:project) do
    create(
      :project, :in_group, :github_import,
      :import_user_mapping_enabled
    )
  end

  let_it_be(:user) { create(:user) }

  let(:client) { instance_double('Gitlab::GithubImport::Client') }
  let(:issuable) { create(:issue, project: project) }
  let(:commit_id) { nil }
  let(:created_at) { 1.month.ago }

  let(:issue_event) do
    Gitlab::GithubImport::Representation::IssueEvent.from_json_hash(
      'id' => 6501124486,
      'node_id' => 'CE_lADOHK9fA85If7x0zwAAAAGDf0mG',
      'url' => 'https://api.github.com/repos/elhowm/test-import/issues/events/6501124486',
      'actor' => { 'id' => 1000, 'login' => 'github_author' },
      'event' => 'closed',
      'created_at' => created_at.iso8601,
      'commit_id' => commit_id,
      'issue' => { 'number' => issuable.iid, pull_request: issuable.is_a?(MergeRequest) }
    )
  end

  let(:cached_references) { placeholder_user_references(Import::SOURCE_GITHUB, project.import_state.id) }

  before do
    allow_next_instance_of(Gitlab::GithubImport::IssuableFinder) do |finder|
      allow(finder).to receive(:database_id).and_return(issuable.id)
    end
  end

  shared_examples 'new event' do
    it 'creates expected event and state event' do
      importer.execute(issue_event)

      expect(issuable.events.count).to eq 1
      expect(issuable.events[0].attributes)
        .to include expected_event_attrs

      expect(issuable.resource_state_events.count).to eq 1
      expect(issuable.resource_state_events[0].attributes)
        .to include expected_state_event_attrs
    end

    context 'when event is outside the cutoff date and would be pruned' do
      let(:created_at) { (PruneOldEventsWorker::CUTOFF_DATE + 1.minute).ago }

      it 'does not create the event, but does create the state event' do
        importer.execute(issue_event)

        expect(issuable.events.count).to eq 0
        expect(issuable.resource_state_events.count).to eq 1
      end

      context 'when pruning events is disabled' do
        before do
          stub_feature_flags(ops_prune_old_events: false)
        end

        it 'creates the event' do
          importer.execute(issue_event)

          expect(issuable.events.count).to eq 1
        end
      end
    end

    context 'when closed by commit' do
      let!(:closing_commit) { create(:commit, project: project) }
      let(:commit_id) { closing_commit.id }

      it 'creates expected event and state event' do
        importer.execute(issue_event)

        expect(issuable.events.count).to eq 1
        state_event = issuable.resource_state_events.last
        expect(state_event.source_commit).to eq commit_id[0..40]
      end
    end
  end

  shared_examples 'push placeholder references' do
    it 'pushes the reference' do
      importer.execute(issue_event)

      expect(cached_references).to match_array([
        ['Event', an_instance_of(Integer), 'author_id', source_user.id],
        ['ResourceStateEvent', an_instance_of(Integer), 'user_id', source_user.id]
      ])
    end
  end

  shared_examples 'do not push placeholder references' do
    it 'does not push any reference' do
      importer.execute(issue_event)

      expect(cached_references).to be_empty
    end
  end

  context 'when user mapping is enabled' do
    let_it_be(:source_user) { generate_source_user(project, 1000) }
    let(:mapped_user_id) { source_user.mapped_user_id }
    let(:expected_event_attrs) do
      {
        project_id: project.id,
        author_id: mapped_user_id,
        target_id: issuable.id,
        target_type: issuable.class.name,
        action: 'closed',
        created_at: issue_event.created_at,
        updated_at: issue_event.created_at,
        imported_from: 'github'
      }.stringify_keys
    end

    context 'with Issue' do
      let(:expected_state_event_attrs) do
        {
          user_id: mapped_user_id,
          issue_id: issuable.id,
          state: 'closed',
          created_at: issue_event.created_at,
          imported_from: 'github'
        }.stringify_keys
      end

      it_behaves_like 'new event'
      it_behaves_like 'push placeholder references'
    end

    context 'with MergeRequest' do
      let(:issuable) { create(:merge_request, source_project: project, target_project: project) }
      let(:expected_state_event_attrs) do
        {
          user_id: mapped_user_id,
          merge_request_id: issuable.id,
          state: 'closed',
          created_at: issue_event.created_at,
          imported_from: 'github'
        }.stringify_keys
      end

      it_behaves_like 'new event'
      it_behaves_like 'push placeholder references'
    end

    context 'when importing into a personal namespace' do
      let_it_be(:user_namespace) { create(:namespace) }
      let(:mapped_user_id) { user_namespace.owner_id }

      before_all do
        project.update!(namespace: user_namespace)
      end

      context 'with Issue' do
        let(:expected_state_event_attrs) do
          {
            user_id: mapped_user_id,
            issue_id: issuable.id,
            state: 'closed',
            created_at: issue_event.created_at,
            imported_from: 'github'
          }.stringify_keys
        end

        it_behaves_like 'new event'
        it_behaves_like 'do not push placeholder references'
      end

      context 'with MergeRequest' do
        let(:issuable) { create(:merge_request, source_project: project, target_project: project) }
        let(:expected_state_event_attrs) do
          {
            user_id: mapped_user_id,
            merge_request_id: issuable.id,
            state: 'closed',
            created_at: issue_event.created_at,
            imported_from: 'github'
          }.stringify_keys
        end

        it_behaves_like 'new event'
        it_behaves_like 'do not push placeholder references'
      end
    end
  end

  context 'when user mapping is disabled' do
    let(:mapped_user_id) { user.id }
    let(:expected_event_attrs) do
      {
        project_id: project.id,
        author_id: mapped_user_id,
        target_id: issuable.id,
        target_type: issuable.class.name,
        action: 'closed',
        created_at: issue_event.created_at,
        updated_at: issue_event.created_at,
        imported_from: 'github'
      }.stringify_keys
    end

    before do
      project.build_or_assign_import_data(data: { user_contribution_mapping_enabled: false }).save!
      allow_next_instance_of(Gitlab::GithubImport::UserFinder) do |finder|
        allow(finder).to receive(:find).with(1000, 'github_author').and_return(user.id)
      end
    end

    context 'with Issue' do
      let(:expected_state_event_attrs) do
        {
          user_id: mapped_user_id,
          issue_id: issuable.id,
          state: 'closed',
          created_at: issue_event.created_at,
          imported_from: 'github'
        }.stringify_keys
      end

      it_behaves_like 'new event'
      it_behaves_like 'do not push placeholder references'
    end

    context 'with MergeRequest' do
      let(:issuable) { create(:merge_request, source_project: project, target_project: project) }
      let(:expected_state_event_attrs) do
        {
          user_id: mapped_user_id,
          merge_request_id: issuable.id,
          state: 'closed',
          created_at: issue_event.created_at,
          imported_from: 'github'
        }.stringify_keys
      end

      it_behaves_like 'new event'
      it_behaves_like 'do not push placeholder references'
    end
  end
end
