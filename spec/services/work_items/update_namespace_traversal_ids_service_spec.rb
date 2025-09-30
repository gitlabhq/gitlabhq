# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::UpdateNamespaceTraversalIdsService, feature_category: :portfolio_management do
  describe '.execute' do
    it 'instantiates a new service object and calls execute' do
      expect_next_instance_of(described_class, :namespace) do |instance|
        expect(instance).to receive(:execute)
      end

      described_class.execute(:namespace)
    end
  end

  describe '#execute' do
    let_it_be(:old_parent) { create(:group) }
    let_it_be(:new_parent) { create(:group) }

    subject(:update_namespace_traversal_ids) { described_class.execute(namespace) }

    context 'when executed in parallel' do
      include ExclusiveLeaseHelpers

      let(:lease_key) { "work_items:#{namespace.id}:update_namespace_traversal_ids" }
      let_it_be(:namespace) { create(:group) }
      let_it_be(:new_parent) { create(:group) }
      let_it_be(:work_item) { create(:work_item, :group_level, namespace: namespace) }

      before do
        # Speed up retries to avoid long-running tests
        stub_const("#{described_class}::LEASE_TRY_AFTER", 0.01)
        stub_exclusive_lease_taken(lease_key)
        namespace.update!(traversal_ids: [new_parent.id, namespace.id])
      end

      it 'does not permit parallel execution on the same namespace' do
        expect { update_namespace_traversal_ids }.to raise_error(Gitlab::ExclusiveLeaseHelpers::FailedToObtainLockError)
          .and not_change { work_item.reload.namespace_traversal_ids }
      end

      it 'allows parallel execution on different projects' do
        expect { described_class.new(new_parent).execute }.not_to raise_error
      end
    end

    context 'when namespace is a group' do
      let_it_be(:group_namespace) { create(:group, parent: old_parent) }
      let_it_be(:other_namespace) { create(:group, parent: old_parent) }

      let_it_be(:group_issue1) { create(:work_item, :group_level, namespace: group_namespace) }
      let_it_be(:group_issue2) { create(:work_item, :group_level, namespace: group_namespace) }
      let_it_be(:other_issue) { create(:work_item, :group_level, namespace: other_namespace) }

      let(:namespace) { group_namespace }

      before do
        group_namespace.update!(traversal_ids: [new_parent.id, group_namespace.id])
        other_namespace.update!(traversal_ids: [new_parent.id, other_namespace.id])
      end

      it 'updates traversal ids for work items belonging to the group namespace' do
        expect { update_namespace_traversal_ids }
          .to change { group_issue1.reload.namespace_traversal_ids }
            .from([old_parent.id, group_namespace.id]).to([new_parent.id, group_namespace.id])
          .and change { group_issue2.reload.namespace_traversal_ids }
            .from([old_parent.id, group_namespace.id]).to([new_parent.id, group_namespace.id])
          .and not_change { other_issue.reload.namespace_traversal_ids }
      end
    end

    context 'when namespace is a project' do
      let_it_be(:project_namespace) { create(:project_namespace, parent: old_parent) }
      let_it_be(:project_issue1) { create(:work_item, project: project_namespace.project) }
      let_it_be(:project_issue2) { create(:work_item, project: project_namespace.project) }

      let_it_be(:other_project_namespace) { create(:project_namespace, parent: old_parent) }
      let_it_be(:other_issue) { create(:work_item, project: other_project_namespace.project) }

      let(:namespace) { project_namespace }

      before do
        project_namespace.update!(traversal_ids: [new_parent.id, project_namespace.id])
      end

      it 'updates traversal ids for work items belonging to the project namespace' do
        expect { update_namespace_traversal_ids }
          .to change { project_issue1.reload.namespace_traversal_ids }
            .from([old_parent.id, project_namespace.id]).to([new_parent.id, project_namespace.id])
          .and change { project_issue2.reload.namespace_traversal_ids }
            .from([old_parent.id, project_namespace.id]).to([new_parent.id, project_namespace.id])
          .and not_change { other_issue.reload.namespace_traversal_ids }
      end
    end
  end
end
