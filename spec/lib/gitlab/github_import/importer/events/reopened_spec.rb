# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::Importer::Events::Reopened, :clean_gitlab_redis_shared_state, :aggregate_failures, feature_category: :importers do
  include Import::UserMappingHelper

  subject(:importer) { described_class.new(project, client) }

  let_it_be(:project) do
    create(
      :project, :in_group, :github_import,
      :import_user_mapping_enabled, :user_mapping_to_personal_namespace_owner_enabled
    )
  end

  let_it_be(:source_user) { generate_source_user(project, 1000) }
  let_it_be(:user) { create(:user) }

  let(:client) { instance_double('Gitlab::GithubImport::Client') }
  let(:issuable) { create(:issue, project: project) }
  let(:created_at) { 1.month.ago }

  let(:issue_event) do
    Gitlab::GithubImport::Representation::IssueEvent.from_json_hash(
      'id' => 6501124486,
      'node_id' => 'CE_lADOHK9fA85If7x0zwAAAAGDf0mG',
      'url' => 'https://api.github.com/repos/elhowm/test-import/issues/events/6501124486',
      'actor' => { id: 1000, login: 'github_author' },
      'event' => 'reopened',
      'created_at' => created_at.iso8601,
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

  shared_examples 'push placeholder references' do
    it 'pushes the references' do
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
    let(:mapped_user_id) { source_user.mapped_user_id }

    let(:expected_event_attrs) do
      {
        project_id: project.id,
        author_id: mapped_user_id,
        target_id: issuable.id,
        target_type: issuable.class.name,
        action: 'reopened',
        created_at: issue_event.created_at,
        updated_at: issue_event.created_at,
        imported_from: 'github'
      }.stringify_keys
    end

    before do
      project.build_or_assign_import_data(data: { user_contribution_mapping_enabled: true })
    end

    context 'with Issue' do
      let(:expected_state_event_attrs) do
        {
          user_id: mapped_user_id,
          issue_id: issuable.id,
          state: 'reopened',
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
          state: 'reopened',
          created_at: issue_event.created_at,
          imported_from: 'github'
        }.stringify_keys
      end

      it_behaves_like 'new event'
      it_behaves_like 'push placeholder references'
    end
  end

  context 'when user mapping is disabled' do
    let(:expected_event_attrs) do
      {
        project_id: project.id,
        author_id: user.id,
        target_id: issuable.id,
        target_type: issuable.class.name,
        action: 'reopened',
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
          user_id: user.id,
          issue_id: issuable.id,
          state: 'reopened',
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
          state: 'reopened',
          created_at: issue_event.created_at,
          imported_from: 'github'
        }.stringify_keys
      end

      it_behaves_like 'new event'
      it_behaves_like 'do not push placeholder references'
    end
  end
end
