# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::Importer::Events::ChangedLabel, :clean_gitlab_redis_shared_state, feature_category: :importers do
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
  let(:label) { create(:label, project: project) }
  let(:label_title) { label.title }
  let(:label_id) { label.id }

  let(:issue_event) do
    Gitlab::GithubImport::Representation::IssueEvent.from_json_hash(
      'id' => 6501124486,
      'actor' => { 'id' => 1000, 'login' => 'github_author' },
      'event' => event_type,
      'commit_id' => nil,
      'label_title' => label_title,
      'created_at' => '2022-04-26 18:30:53 UTC',
      'issue' => { 'number' => issuable.iid, pull_request: issuable.is_a?(MergeRequest) }
    )
  end

  let(:cached_references) { placeholder_user_references(Import::SOURCE_GITHUB, project.import_state.id) }

  shared_examples 'new event' do
    it 'creates a new label event' do
      expect { importer.execute(issue_event) }.to change { issuable.resource_label_events.count }
        .from(0).to(1)
      expect(issuable.resource_label_events.last)
        .to have_attributes(expected_event_attrs)
    end
  end

  shared_examples 'push placeholder reference' do
    it 'pushes the reference' do
      importer.execute(issue_event)

      expect(cached_references).to match_array([
        ['ResourceLabelEvent', an_instance_of(Integer), 'user_id', source_user.id]
      ])
    end
  end

  shared_examples 'do not push placeholder reference' do
    it 'does not push any reference' do
      importer.execute(issue_event)

      expect(cached_references).to be_empty
    end
  end

  before do
    allow_next_instance_of(Gitlab::GithubImport::IssuableFinder) do |finder|
      allow(finder).to receive(:database_id).and_return(issuable.id)
    end
  end

  context 'when user mapping is enabled' do
    let_it_be(:source_user) { generate_source_user(project, 1000) }
    let(:mapped_author_id) { source_user.mapped_user_id }
    let(:event_attrs) do
      {
        user_id: mapped_author_id,
        label_id: label_id,
        created_at: issue_event.created_at,
        imported_from: 'github'
      }.stringify_keys
    end

    context 'with Issue' do
      context 'when importing event with associated label' do
        before do
          allow(Gitlab::Cache::Import::Caching).to receive(:read_integer).and_return(label.id)
        end

        context 'when importing a labeled event' do
          let(:event_type) { 'labeled' }
          let(:expected_event_attrs) { event_attrs.merge(issue_id: issuable.id, action: 'add') }

          it_behaves_like 'new event'
          it_behaves_like 'push placeholder reference'
        end

        context 'when importing an unlabeled event' do
          let(:event_type) { 'unlabeled' }
          let(:expected_event_attrs) { event_attrs.merge(issue_id: issuable.id, action: 'remove') }

          it_behaves_like 'new event'
          it_behaves_like 'push placeholder reference'
        end
      end

      context 'when importing event without associated label' do
        before do
          allow(Gitlab::Cache::Import::Caching).to receive(:read_integer).and_return(nil)
        end

        let(:label_title) { 'deleted_label' }
        let(:label_id) { nil }
        let(:event_type) { 'labeled' }
        let(:expected_event_attrs) { event_attrs.merge(issue_id: issuable.id, action: 'add') }

        it_behaves_like 'new event'
        it_behaves_like 'push placeholder reference'
      end
    end

    context 'with MergeRequest' do
      let(:issuable) { create(:merge_request, source_project: project, target_project: project) }

      context 'when importing event with associated label' do
        before do
          allow(Gitlab::Cache::Import::Caching).to receive(:read_integer).and_return(label.id)
        end

        context 'when importing a labeled event' do
          let(:event_type) { 'labeled' }
          let(:expected_event_attrs) { event_attrs.merge(merge_request_id: issuable.id, action: 'add') }

          it_behaves_like 'new event'
          it_behaves_like 'push placeholder reference'
        end

        context 'when importing an unlabeled event' do
          let(:event_type) { 'unlabeled' }
          let(:expected_event_attrs) { event_attrs.merge(merge_request_id: issuable.id, action: 'remove') }

          it_behaves_like 'new event'
          it_behaves_like 'push placeholder reference'
        end
      end

      context 'when importing event without associated label' do
        before do
          allow(Gitlab::Cache::Import::Caching).to receive(:read_integer).and_return(nil)
        end

        let(:label_title) { 'deleted_label' }
        let(:label_id) { nil }
        let(:event_type) { 'labeled' }
        let(:expected_event_attrs) { event_attrs.merge(merge_request_id: issuable.id, action: 'add') }

        it_behaves_like 'new event'
        it_behaves_like 'push placeholder reference'
      end
    end

    context 'when importing into a personal namespace' do
      let_it_be(:user_namespace) { create(:namespace) }
      let(:mapped_author_id) { user_namespace.owner_id }

      before_all do
        project.update!(namespace: user_namespace)
      end

      context 'with Issue' do
        context 'when importing event with associated label' do
          before do
            allow(Gitlab::Cache::Import::Caching).to receive(:read_integer).and_return(label.id)
          end

          context 'when importing a labeled event' do
            let(:event_type) { 'labeled' }
            let(:expected_event_attrs) { event_attrs.merge(issue_id: issuable.id, action: 'add') }

            it_behaves_like 'new event'
            it_behaves_like 'do not push placeholder reference'
          end

          context 'when importing an unlabeled event' do
            let(:event_type) { 'unlabeled' }
            let(:expected_event_attrs) { event_attrs.merge(issue_id: issuable.id, action: 'remove') }

            it_behaves_like 'new event'
            it_behaves_like 'do not push placeholder reference'
          end
        end

        context 'when importing event without associated label' do
          before do
            allow(Gitlab::Cache::Import::Caching).to receive(:read_integer).and_return(nil)
          end

          let(:label_title) { 'deleted_label' }
          let(:label_id) { nil }
          let(:event_type) { 'labeled' }
          let(:expected_event_attrs) { event_attrs.merge(issue_id: issuable.id, action: 'add') }

          it_behaves_like 'new event'
          it_behaves_like 'do not push placeholder reference'
        end
      end

      context 'with MergeRequest' do
        let(:issuable) { create(:merge_request, source_project: project, target_project: project) }

        context 'when importing event with associated label' do
          before do
            allow(Gitlab::Cache::Import::Caching).to receive(:read_integer).and_return(label.id)
          end

          context 'when importing a labeled event' do
            let(:event_type) { 'labeled' }
            let(:expected_event_attrs) { event_attrs.merge(merge_request_id: issuable.id, action: 'add') }

            it_behaves_like 'new event'
            it_behaves_like 'do not push placeholder reference'
          end

          context 'when importing an unlabeled event' do
            let(:event_type) { 'unlabeled' }
            let(:expected_event_attrs) { event_attrs.merge(merge_request_id: issuable.id, action: 'remove') }

            it_behaves_like 'new event'
            it_behaves_like 'do not push placeholder reference'
          end
        end

        context 'when importing event without associated label' do
          before do
            allow(Gitlab::Cache::Import::Caching).to receive(:read_integer).and_return(nil)
          end

          let(:label_title) { 'deleted_label' }
          let(:label_id) { nil }
          let(:event_type) { 'labeled' }
          let(:expected_event_attrs) { event_attrs.merge(merge_request_id: issuable.id, action: 'add') }

          it_behaves_like 'new event'
          it_behaves_like 'do not push placeholder reference'
        end
      end
    end
  end

  context 'when user mapping is disabled' do
    let(:mapped_author_id) { user.id }
    let(:event_attrs) do
      {
        user_id: mapped_author_id,
        label_id: label_id,
        created_at: issue_event.created_at,
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
      context 'when importing event with associated label' do
        before do
          allow(Gitlab::Cache::Import::Caching).to receive(:read_integer).and_return(label.id)
        end

        context 'when importing a labeled event' do
          let(:event_type) { 'labeled' }
          let(:expected_event_attrs) { event_attrs.merge(issue_id: issuable.id, action: 'add') }

          it_behaves_like 'new event'
          it_behaves_like 'do not push placeholder reference'
        end

        context 'when importing an unlabeled event' do
          let(:event_type) { 'unlabeled' }
          let(:expected_event_attrs) { event_attrs.merge(issue_id: issuable.id, action: 'remove') }

          it_behaves_like 'new event'
          it_behaves_like 'do not push placeholder reference'
        end
      end

      context 'when importing event without associated label' do
        before do
          allow(Gitlab::Cache::Import::Caching).to receive(:read_integer).and_return(nil)
        end

        let(:label_title) { 'deleted_label' }
        let(:label_id) { nil }
        let(:event_type) { 'labeled' }
        let(:expected_event_attrs) { event_attrs.merge(issue_id: issuable.id, action: 'add') }

        it_behaves_like 'new event'
        it_behaves_like 'do not push placeholder reference'
      end
    end

    context 'with MergeRequest' do
      let(:issuable) { create(:merge_request, source_project: project, target_project: project) }

      context 'when importing event with associated label' do
        before do
          allow(Gitlab::Cache::Import::Caching).to receive(:read_integer).and_return(label.id)
        end

        context 'when importing a labeled event' do
          let(:event_type) { 'labeled' }
          let(:expected_event_attrs) { event_attrs.merge(merge_request_id: issuable.id, action: 'add') }

          it_behaves_like 'new event'
          it_behaves_like 'do not push placeholder reference'
        end

        context 'when importing an unlabeled event' do
          let(:event_type) { 'unlabeled' }
          let(:expected_event_attrs) { event_attrs.merge(merge_request_id: issuable.id, action: 'remove') }

          it_behaves_like 'new event'
          it_behaves_like 'do not push placeholder reference'
        end
      end

      context 'when importing event without associated label' do
        before do
          allow(Gitlab::Cache::Import::Caching).to receive(:read_integer).and_return(nil)
        end

        let(:label_title) { 'deleted_label' }
        let(:label_id) { nil }
        let(:event_type) { 'labeled' }
        let(:expected_event_attrs) { event_attrs.merge(merge_request_id: issuable.id, action: 'add') }

        it_behaves_like 'new event'
        it_behaves_like 'do not push placeholder reference'
      end
    end
  end
end
