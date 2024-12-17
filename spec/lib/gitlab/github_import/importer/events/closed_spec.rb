# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::Importer::Events::Closed, feature_category: :importers do
  subject(:importer) { described_class.new(project, client) }

  let_it_be(:project) { create(:project, :repository, :with_import_url) }
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
      'actor' => { 'id' => user.id, 'login' => user.username },
      'event' => 'closed',
      'created_at' => created_at.iso8601,
      'commit_id' => commit_id,
      'issue' => { 'number' => issuable.iid, pull_request: issuable.is_a?(MergeRequest) }
    )
  end

  let(:expected_event_attrs) do
    {
      project_id: project.id,
      author_id: user.id,
      target_id: issuable.id,
      target_type: issuable.class.name,
      action: 'closed',
      created_at: issue_event.created_at,
      updated_at: issue_event.created_at,
      imported_from: 'github'
    }.stringify_keys
  end

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
    it 'pushes the references' do
      expect(subject)
      .to receive(:push_with_record)
      .with(
        an_instance_of(Event),
        :author_id,
        user.id,
        an_instance_of(Gitlab::Import::SourceUserMapper)
      )

      expect(subject)
      .to receive(:push_with_record)
      .with(
        an_instance_of(ResourceStateEvent),
        :user_id,
        user.id,
        an_instance_of(Gitlab::Import::SourceUserMapper)
      )

      importer.execute(issue_event)
    end
  end

  shared_examples 'do not push placeholder references' do
    it 'does not push any references' do
      expect(subject)
      .not_to receive(:push_with_record)

      importer.execute(issue_event)
    end
  end

  context 'when user mapping is enabled' do
    let_it_be(:source_user) do
      create(
        :import_source_user,
        placeholder_user_id: user.id,
        source_user_identifier: user.id,
        source_username: user.username,
        source_hostname: project.import_url,
        namespace_id: project.root_ancestor.id
      )
    end

    before do
      project.build_or_assign_import_data(data: { user_contribution_mapping_enabled: true })
    end

    context 'with Issue' do
      let(:expected_state_event_attrs) do
        {
          user_id: user.id,
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
          user_id: user.id,
          merge_request_id: issuable.id,
          state: 'closed',
          created_at: issue_event.created_at,
          imported_from: 'github'
        }.stringify_keys
      end

      it_behaves_like 'new event'
      it_behaves_like 'push placeholder references'
    end
  end

  context 'when user mapping is disabled' do
    before do
      allow_next_instance_of(Gitlab::GithubImport::UserFinder) do |finder|
        allow(finder).to receive(:find).with(user.id, user.username).and_return(user.id)
      end
      project.build_or_assign_import_data(data: { user_contribution_mapping_enabled: false })
    end

    context 'with Issue' do
      let(:expected_state_event_attrs) do
        {
          user_id: user.id,
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
          user_id: user.id,
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
