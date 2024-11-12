# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::Importer::Events::ChangedMilestone, feature_category: :importers do
  subject(:importer) { described_class.new(project, client) }

  let_it_be(:project) { create(:project, :repository, :with_import_url) }
  let_it_be(:user) { create(:user) }

  let(:client) { instance_double('Gitlab::GithubImport::Client') }
  let(:issuable) { create(:issue, project: project) }
  let!(:milestone) { create(:milestone, project: project) }

  let(:issue_event) do
    Gitlab::GithubImport::Representation::IssueEvent.from_json_hash(
      'id' => 6501124486,
      'actor' => { 'id' => user.id, 'login' => user.username },
      'event' => event_type,
      'commit_id' => nil,
      'milestone_title' => milestone_title,
      'issue_db_id' => issuable.id,
      'created_at' => '2022-04-26 18:30:53 UTC',
      'issue' => { 'number' => issuable.iid, pull_request: issuable.is_a?(MergeRequest) }
    )
  end

  let(:event_attrs) do
    {
      user_id: user.id,
      milestone_id: milestone.id,
      state: 'opened',
      created_at: issue_event.created_at,
      imported_from: 'github'

    }.stringify_keys
  end

  shared_examples 'new event' do
    context 'when a matching milestone exists in GitLab' do
      let(:milestone_title) { milestone.title }

      it 'creates a new milestone event' do
        expect { importer.execute(issue_event) }.to change { issuable.resource_milestone_events.count }
          .from(0).to(1)
        expect(issuable.resource_milestone_events.last)
          .to have_attributes(expected_event_attrs)
      end
    end

    context 'when a matching milestone does not exist in GitLab' do
      let(:milestone_title) { 'A deleted milestone title' }

      it 'does not create a new milestone event without a milestone' do
        expect { importer.execute(issue_event) }.not_to change { issuable.resource_milestone_events.count }
      end
    end
  end

  shared_examples 'push placeholder reference' do
    let(:milestone_title) { milestone.title }

    it 'pushes the reference' do
      expect(subject)
      .to receive(:push_with_record)
      .with(
        an_instance_of(ResourceMilestoneEvent),
        :user_id,
        user.id,
        an_instance_of(Gitlab::Import::SourceUserMapper)
      )

      importer.execute(issue_event)
    end
  end

  shared_examples 'do not push placeholder reference' do
    let(:milestone_title) { milestone.title }

    it 'does not push any reference' do
      expect(subject)
      .not_to receive(:push_with_record)

      importer.execute(issue_event)
    end
  end

  describe '#execute' do
    before do
      allow(Gitlab::Cache::Import::Caching).to receive(:read_integer).and_return(milestone.id)
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
        context 'when importing a milestoned event' do
          let(:event_type) { 'milestoned' }
          let(:expected_event_attrs) { event_attrs.merge(issue_id: issuable.id, action: 'add') }

          it_behaves_like 'new event'
          it_behaves_like 'push placeholder reference'
        end

        context 'when importing demilestoned event' do
          let(:event_type) { 'demilestoned' }
          let(:expected_event_attrs) { event_attrs.merge(issue_id: issuable.id, action: 'remove') }

          it_behaves_like 'new event'
          it_behaves_like 'push placeholder reference'
        end
      end

      context 'with MergeRequest' do
        let(:issuable) { create(:merge_request, source_project: project, target_project: project) }

        context 'when importing a milestoned event' do
          let(:event_type) { 'milestoned' }
          let(:expected_event_attrs) { event_attrs.merge(merge_request_id: issuable.id, action: 'add') }

          it_behaves_like 'new event'
          it_behaves_like 'push placeholder reference'
        end

        context 'when importing demilestoned event' do
          let(:event_type) { 'demilestoned' }
          let(:expected_event_attrs) { event_attrs.merge(merge_request_id: issuable.id, action: 'remove') }

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
        context 'when importing a milestoned event' do
          let(:event_type) { 'milestoned' }
          let(:expected_event_attrs) { event_attrs.merge(issue_id: issuable.id, action: 'add') }

          it_behaves_like 'new event'
          it_behaves_like 'do not push placeholder reference'
        end

        context 'when importing demilestoned event' do
          let(:event_type) { 'demilestoned' }
          let(:expected_event_attrs) { event_attrs.merge(issue_id: issuable.id, action: 'remove') }

          it_behaves_like 'new event'
          it_behaves_like 'do not push placeholder reference'
        end
      end

      context 'with MergeRequest' do
        let(:issuable) { create(:merge_request, source_project: project, target_project: project) }

        context 'when importing a milestoned event' do
          let(:event_type) { 'milestoned' }
          let(:expected_event_attrs) { event_attrs.merge(merge_request_id: issuable.id, action: 'add') }

          it_behaves_like 'new event'
          it_behaves_like 'do not push placeholder reference'
        end

        context 'when importing demilestoned event' do
          let(:event_type) { 'demilestoned' }
          let(:expected_event_attrs) { event_attrs.merge(merge_request_id: issuable.id, action: 'remove') }

          it_behaves_like 'new event'
          it_behaves_like 'do not push placeholder reference'
        end
      end
    end
  end
end
