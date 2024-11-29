# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::Importer::Events::Merged, feature_category: :importers do
  subject(:importer) { described_class.new(project, client) }

  let_it_be(:project) { create(:project, :repository, :with_import_url) }
  let_it_be(:user) { create(:user) }

  let(:client) { instance_double('Gitlab::GithubImport::Client') }
  let(:merge_request) { create(:merge_request, source_project: project, target_project: project) }
  let(:commit_id) { nil }
  let(:created_at) { 1.month.ago }

  let(:issue_event) do
    Gitlab::GithubImport::Representation::IssueEvent.from_json_hash(
      'id' => 6501124486,
      'node_id' => 'CE_lADOHK9fA85If7x0zwAAAAGDf0mG',
      'url' => 'https://api.github.com/repos/elhowm/test-import/issues/events/6501124486',
      'actor' => { 'id' => user.id, 'login' => user.username },
      'event' => 'merged',
      'created_at' => created_at.iso8601,
      'commit_id' => commit_id,
      'issue' => { 'number' => merge_request.iid, pull_request: true }
    )
  end

  before do
    allow_next_instance_of(Gitlab::GithubImport::IssuableFinder) do |finder|
      allow(finder).to receive(:database_id).and_return(merge_request.id)
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
    it 'does not push references' do
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

    it 'creates expected event and state event' do
      importer.execute(issue_event)

      expect(merge_request.events.count).to eq 1
      expect(merge_request.events.first).to have_attributes(
        project_id: project.id,
        author_id: user.id,
        target_id: merge_request.id,
        target_type: merge_request.class.name,
        action: 'merged',
        created_at: issue_event.created_at,
        updated_at: issue_event.created_at,
        imported_from: 'github'
      )

      expect(merge_request.resource_state_events.count).to eq 1
      expect(merge_request.resource_state_events.first).to have_attributes(
        user_id: user.id,
        merge_request_id: merge_request.id,
        state: 'merged',
        created_at: issue_event.created_at,
        close_after_error_tracking_resolve: false,
        close_auto_resolve_prometheus_alert: false
      )
    end

    context 'when event is outside the cutoff date and would be pruned' do
      let(:created_at) { (PruneOldEventsWorker::CUTOFF_DATE + 1.minute).ago }

      it 'does not create the event, but does create the state event' do
        importer.execute(issue_event)

        expect(merge_request.events.count).to eq 0
        expect(merge_request.resource_state_events.count).to eq 1
      end

      context 'when pruning events is disabled' do
        before do
          stub_feature_flags(ops_prune_old_events: false)
        end

        it 'creates the event' do
          importer.execute(issue_event)

          expect(merge_request.events.count).to eq 1
        end
      end
    end

    context 'when commit ID is present' do
      let!(:commit) { create(:commit, project: project) }
      let(:commit_id) { commit.id }

      it 'creates expected event and state event' do
        importer.execute(issue_event)

        expect(merge_request.events.count).to eq 1
        state_event = merge_request.resource_state_events.last
        expect(state_event.source_commit).to eq commit_id[0..40]
      end
    end

    it_behaves_like 'push placeholder references'
  end

  context 'when user mapping is disabled' do
    before do
      project.build_or_assign_import_data(data: { user_contribution_mapping_enabled: false })
      allow_next_instance_of(Gitlab::GithubImport::UserFinder) do |finder|
        allow(finder).to receive(:find).with(user.id, user.username).and_return(user.id)
      end
    end

    it 'creates expected event and state event' do
      importer.execute(issue_event)

      expect(merge_request.events.count).to eq 1
      expect(merge_request.events.first).to have_attributes(
        project_id: project.id,
        author_id: user.id,
        target_id: merge_request.id,
        target_type: merge_request.class.name,
        action: 'merged',
        created_at: issue_event.created_at,
        updated_at: issue_event.created_at,
        imported_from: 'github'
      )

      expect(merge_request.resource_state_events.count).to eq 1
      expect(merge_request.resource_state_events.first).to have_attributes(
        user_id: user.id,
        merge_request_id: merge_request.id,
        state: 'merged',
        created_at: issue_event.created_at,
        close_after_error_tracking_resolve: false,
        close_auto_resolve_prometheus_alert: false
      )
    end

    it 'creates a merged by note' do
      expect { importer.execute(issue_event) }.to change { Note.count }.by(1)

      last_note = merge_request.notes.last
      expect(last_note.created_at).to eq(issue_event.created_at)
      expect(last_note.author).to eq(merge_request.author)
      expect(last_note.note).to eq("*Merged by: #{user.username} at #{issue_event.created_at}*")
    end

    context 'when commit ID is present' do
      let!(:commit) { create(:commit, project: project) }
      let(:commit_id) { commit.id }

      it 'creates expected event and state event' do
        importer.execute(issue_event)

        expect(merge_request.events.count).to eq 1
        state_event = merge_request.resource_state_events.last
        expect(state_event.source_commit).to eq commit_id[0..40]
      end
    end

    it_behaves_like 'do not push placeholder references'
  end
end
