# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::NamespaceChanges::BroadcastService, feature_category: :planning_views do
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:work_item) { create(:work_item, project: project) }

  let(:action) { :created }
  let(:updated_changes) { nil }

  subject(:execute) { described_class.new(work_item, action: action, updated_changes: updated_changes).execute }

  before do
    allow(GitlabSchema.subscriptions).to receive(:trigger)
  end

  shared_examples 'broadcasts the event' do
    it 'triggers namespaceWorkItemChanges for the namespace and its ancestors' do
      execute

      [project.project_namespace, group].each do |namespace|
        expect(GitlabSchema.subscriptions).to have_received(:trigger).with(
          'namespaceWorkItemChanges',
          { namespace_id: namespace.to_gid },
          { work_item_id: work_item.id, action: action }
        )
      end
    end
  end

  shared_examples 'does not broadcast' do
    it 'does not trigger namespaceWorkItemChanges' do
      execute

      expect(GitlabSchema.subscriptions).not_to have_received(:trigger)
    end
  end

  context 'for a created action' do
    it_behaves_like 'broadcasts the event'
  end

  context 'for a deleted action' do
    let(:action) { :deleted }

    it_behaves_like 'broadcasts the event'
  end

  context 'for an updated action' do
    let(:action) { :updated }

    context 'when a relevant field changed' do
      let(:updated_changes) { %w[title] }

      it_behaves_like 'broadcasts the event'
    end

    context 'when only irrelevant fields changed' do
      let(:updated_changes) { %w[description] }

      it_behaves_like 'does not broadcast'
    end

    context 'when no changed fields are given' do
      it_behaves_like 'does not broadcast'
    end

    context 'when the work item became confidential' do
      let_it_be(:work_item) { create(:work_item, :confidential, project: project) }

      let(:updated_changes) { %w[confidential] }

      it_behaves_like 'broadcasts the event'
    end

    context 'when the work item stopped being confidential' do
      let(:updated_changes) { %w[confidential] }

      it_behaves_like 'broadcasts the event'
    end
  end

  context 'when the flag is enabled only for the root ancestor' do
    let_it_be(:subgroup) { create(:group, parent: group) }
    let_it_be(:nested_project) { create(:project, group: subgroup) }
    let_it_be(:work_item) { create(:work_item, project: nested_project) }

    before do
      stub_feature_flags(work_items_realtime_broadcast: group)
    end

    it 'broadcasts' do
      execute

      expect(GitlabSchema.subscriptions).to have_received(:trigger).with(
        'namespaceWorkItemChanges', { namespace_id: group.to_gid }, anything
      )
    end
  end

  context 'when work_items_realtime_broadcast is disabled' do
    before do
      stub_feature_flags(work_items_realtime_broadcast: false)
    end

    it_behaves_like 'does not broadcast'
  end

  context 'when the work item is confidential' do
    let_it_be(:work_item) { create(:work_item, :confidential, project: project) }

    [:created, :deleted].each do |confidential_action|
      context "for a #{confidential_action} action" do
        let(:action) { confidential_action }

        it_behaves_like 'does not broadcast'
      end
    end

    context 'for an updated action with a relevant change' do
      let(:action) { :updated }
      let(:updated_changes) { %w[title] }

      it_behaves_like 'does not broadcast'
    end
  end

  context 'when the work item is in a nested group hierarchy' do
    let_it_be(:subgroup) { create(:group, parent: group) }
    let_it_be(:nested_project) { create(:project, group: subgroup) }
    let_it_be(:work_item) { create(:work_item, project: nested_project) }

    it 'broadcasts to the work item namespace and every ancestor', :aggregate_failures do
      execute

      [nested_project.project_namespace, subgroup, group].each do |namespace|
        expect(GitlabSchema.subscriptions).to have_received(:trigger).with(
          'namespaceWorkItemChanges',
          { namespace_id: namespace.to_gid },
          { work_item_id: work_item.id, action: :created }
        )
      end
    end
  end

  context 'when the project sits in a personal namespace' do
    let_it_be(:personal_project) { create(:project) }
    let_it_be(:work_item) { create(:work_item, project: personal_project) }

    it 'broadcasts to the project namespace and the user namespace', :aggregate_failures do
      execute

      [personal_project.project_namespace, personal_project.namespace].each do |namespace|
        expect(GitlabSchema.subscriptions).to have_received(:trigger).with(
          'namespaceWorkItemChanges',
          { namespace_id: namespace.to_gid },
          { work_item_id: work_item.id, action: action }
        )
      end
    end
  end

  context 'when a namespace is rate limited' do
    before do
      allow(Gitlab::ApplicationRateLimiter).to receive(:peek)
        .with(:namespace_work_item_changes_broadcast, scope: anything).and_return(false)
      allow(Gitlab::ApplicationRateLimiter).to receive(:peek)
        .with(:namespace_work_item_changes_broadcast, scope: group).and_return(true)
      allow(Gitlab::ApplicationRateLimiter).to receive(:throttled?)
        .with(:namespace_work_item_changes_broadcast, scope: anything).and_return(false)
      allow(Gitlab::ApplicationRateLimiter).to receive(:throttled?)
        .with(:namespace_work_item_changes_broadcast, scope: group).and_return(true)
    end

    it 'skips only the rate limited namespace' do
      execute

      expect(GitlabSchema.subscriptions).to have_received(:trigger).with(
        'namespaceWorkItemChanges',
        { namespace_id: project.project_namespace.to_gid },
        { work_item_id: work_item.id, action: action }
      )
      expect(GitlabSchema.subscriptions).not_to have_received(:trigger).with(
        'namespaceWorkItemChanges',
        { namespace_id: group.to_gid },
        anything
      )
    end
  end

  context 'when every namespace is rate limited' do
    before do
      allow(Gitlab::ApplicationRateLimiter).to receive(:peek)
        .with(:namespace_work_item_changes_broadcast, scope: anything).and_return(true)
      allow(Gitlab::ApplicationRateLimiter).to receive(:throttled?).and_call_original
    end

    it_behaves_like 'does not broadcast'

    it 'skips the readability queries' do
      expect(work_item).not_to receive(:hidden?)

      execute
    end

    it 'leaves the budget untouched' do
      execute

      expect(Gitlab::ApplicationRateLimiter).not_to have_received(:throttled?)
    end
  end

  describe 'work items a namespace member cannot read' do
    let_it_be(:guest_group) { create(:group, :private) }
    let_it_be(:guest) { create(:user, guest_of: guest_group) }

    shared_examples 'a change that is never broadcast' do
      it 'does not broadcast namespace work item changes', :aggregate_failures do
        expect(Ability.allowed?(guest, :read_work_item, unreadable_work_item)).to be(false)

        described_class.new(unreadable_work_item, action: :created).execute
        described_class.new(unreadable_work_item, action: :updated, updated_changes: %w[title]).execute
        described_class.new(unreadable_work_item, action: :deleted).execute

        expect(GitlabSchema.subscriptions).not_to have_received(:trigger)
      end
    end

    context 'when the author is banned' do
      let_it_be(:unreadable_work_item) do
        create(:work_item, project: create(:project, group: guest_group), author: create(:user, :banned))
      end

      it_behaves_like 'a change that is never broadcast'
    end

    context 'when the project has issues disabled' do
      let_it_be(:unreadable_work_item) do
        create(:work_item, project: create(:project, :issues_disabled, group: guest_group))
      end

      it_behaves_like 'a change that is never broadcast'
    end

    context 'when the work item type is unavailable in its namespace' do
      let_it_be(:unreadable_work_item) { create(:work_item, :group_level, namespace: guest_group) }

      before do
        stub_licensed_features(epics: false)
      end

      it_behaves_like 'a change that is never broadcast'
    end
  end

  describe 'policy evaluation' do
    let_it_be(:sibling_work_item) { create(:work_item, project: project) }

    it 'evaluates the policy once per work item type and container in a request' do
      expect(Ability).to receive(:policy_for).with(nil, anything).once.and_call_original

      Gitlab::SafeRequestStore.ensure_request_store do
        described_class.new(work_item, action: :created).execute
        described_class.new(sibling_work_item, action: :created).execute
      end
    end

    it 'evaluates the policy per work item outside a request' do
      expect(Ability).to receive(:policy_for).with(nil, anything).twice.and_call_original

      described_class.new(work_item, action: :created).execute
      described_class.new(sibling_work_item, action: :created).execute
    end
  end

  context 'when external authorization is enabled' do
    before do
      stub_application_setting(
        external_authorization_service_enabled: true,
        external_authorization_service_url: 'https://authorization.example.com'
      )
    end

    it_behaves_like 'does not broadcast'
  end
end
