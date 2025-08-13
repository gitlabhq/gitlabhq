# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::Importer::Events::Merged, :clean_gitlab_redis_shared_state, feature_category: :importers do
  include Import::UserMappingHelper

  subject(:importer) { described_class.new(project, client) }

  let_it_be_with_reload(:project) do
    create(
      :project, :in_group, :github_import,
      :import_user_mapping_enabled, :user_mapping_to_personal_namespace_owner_enabled
    )
  end

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
      'actor' => { 'id' => 1000, 'login' => 'github_author' },
      'event' => 'merged',
      'created_at' => created_at.iso8601,
      'commit_id' => commit_id,
      'issue' => { 'number' => merge_request.iid, pull_request: true }
    )
  end

  let(:cached_references) { placeholder_user_references(Import::SOURCE_GITHUB, project.import_state.id) }

  before do
    allow_next_instance_of(Gitlab::GithubImport::IssuableFinder) do |finder|
      allow(finder).to receive(:database_id).and_return(merge_request.id)
    end
  end

  shared_examples 'push placeholder references' do
    it 'pushes the reference' do
      importer.execute(issue_event)

      expect(cached_references).to match_array([
        ['Event', an_instance_of(Integer), 'author_id', source_user.id],
        ['ResourceStateEvent', an_instance_of(Integer), 'user_id', source_user.id],
        ['MergeRequest::Metrics', an_instance_of(Integer), 'merged_by_id', source_user.id]
      ])
    end
  end

  shared_examples 'do not push placeholder reference' do
    it 'does not push any reference' do
      importer.execute(issue_event)

      expect(cached_references).to be_empty
    end
  end

  context 'when user mapping is enabled' do
    let_it_be(:source_user) { generate_source_user(project, 1000) }

    it 'creates expected event and state event' do
      importer.execute(issue_event)

      expect(merge_request.events.count).to eq 1
      expect(merge_request.events.first).to have_attributes(
        project_id: project.id,
        author_id: source_user.mapped_user_id,
        target_id: merge_request.id,
        target_type: merge_request.class.name,
        action: 'merged',
        created_at: issue_event.created_at,
        updated_at: issue_event.created_at,
        imported_from: 'github'
      )

      expect(merge_request.resource_state_events.count).to eq 1
      expect(merge_request.resource_state_events.first).to have_attributes(
        user_id: source_user.mapped_user_id,
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

    context 'when importing into a personal namespace' do
      let_it_be(:user_namespace) { create(:namespace) }

      before_all do
        project.update!(namespace: user_namespace)
      end

      it 'creates expected event and state event mapped to personal namespace owner' do
        importer.execute(issue_event)

        expect(merge_request.events.count).to eq 1
        expect(merge_request.events.first.author_id).to eq(user_namespace.owner_id)

        expect(merge_request.resource_state_events.count).to eq 1
        expect(merge_request.resource_state_events.first.user_id).to eq(user_namespace.owner_id)
      end

      it_behaves_like 'do not push placeholder reference'

      context 'when user_mapping_to_personal_namespace_owner is disabled' do
        let_it_be(:source_user) { generate_source_user(project, 1000) }

        before_all do
          project.build_or_assign_import_data(
            data: { user_mapping_to_personal_namespace_owner_enabled: false }
          ).save!
        end

        it 'creates expected event and state event' do
          importer.execute(issue_event)

          expect(merge_request.events.count).to eq 1
          expect(merge_request.events.first.author_id).to eq(source_user.mapped_user_id)

          expect(merge_request.resource_state_events.count).to eq 1
          expect(merge_request.resource_state_events.first.user_id).to eq(source_user.mapped_user_id)
        end

        it_behaves_like 'push placeholder references'
      end
    end

    context 'when user mapping is disabled' do
      before do
        project.build_or_assign_import_data(data: { user_contribution_mapping_enabled: false }).save!
        allow_next_instance_of(Gitlab::GithubImport::UserFinder) do |finder|
          allow(finder).to receive(:find).with(1000, 'github_author').and_return(user.id)
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
        expect(last_note.note).to eq("*Merged by: github_author at #{issue_event.created_at}*")
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

      it_behaves_like 'do not push placeholder reference'
    end
  end
end
