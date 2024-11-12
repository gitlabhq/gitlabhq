# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::Importer::Events::ChangedLabel, feature_category: :importers do
  subject(:importer) { described_class.new(project, client) }

  let_it_be(:project) { create(:project, :repository, :with_import_url) }
  let_it_be(:user) { create(:user) }

  let(:client) { instance_double('Gitlab::GithubImport::Client') }
  let(:issuable) { create(:issue, project: project) }
  let(:label) { create(:label, project: project) }
  let(:label_title) { label.title }
  let(:label_id) { label.id }

  let(:issue_event) do
    Gitlab::GithubImport::Representation::IssueEvent.from_json_hash(
      'id' => 6501124486,
      'actor' => { 'id' => user.id, 'login' => user.username },
      'event' => event_type,
      'commit_id' => nil,
      'label_title' => label_title,
      'created_at' => '2022-04-26 18:30:53 UTC',
      'issue' => { 'number' => issuable.iid, pull_request: issuable.is_a?(MergeRequest) }
    )
  end

  let(:event_attrs) do
    {
      user_id: user.id,
      label_id: label_id,
      created_at: issue_event.created_at,
      imported_from: 'github'
    }.stringify_keys
  end

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
      expect(subject)
      .to receive(:push_with_record)
      .with(
        an_instance_of(ResourceLabelEvent),
        :user_id,
        user.id,
        an_instance_of(Gitlab::Import::SourceUserMapper)
      )

      importer.execute(issue_event)
    end
  end

  shared_examples 'do not push placeholder reference' do
    it 'does not push any reference' do
      expect(subject)
      .not_to receive(:push_with_record)

      importer.execute(issue_event)
    end
  end

  before do
    allow_next_instance_of(Gitlab::GithubImport::IssuableFinder) do |finder|
      allow(finder).to receive(:database_id).and_return(issuable.id)
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
  end

  context 'when user mapping is disabled' do
    before do
      project.build_or_assign_import_data(data: { user_contribution_mapping_enabled: false })

      allow_next_instance_of(Gitlab::GithubImport::UserFinder) do |finder|
        allow(finder).to receive(:find).with(user.id, user.username).and_return(user.id)
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
