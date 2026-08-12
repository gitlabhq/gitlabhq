# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::UpdatePositioningNamespaceIdService, feature_category: :portfolio_management do
  def positioning_ns_id(work_item)
    WorkItems::Position.find_by(work_item_id: work_item.id)&.relative_positioning_namespace_id
  end

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

    subject(:update_positioning_namespace_id) { described_class.execute(namespace) }

    context 'when namespace is a group' do
      let_it_be_with_reload(:group_namespace) { create(:group, parent: old_parent) }
      let_it_be_with_reload(:other_namespace) { create(:group, parent: old_parent) }

      let_it_be(:group_issue1) { create(:work_item, :group_level, namespace: group_namespace) }
      let_it_be(:group_issue2) { create(:work_item, :group_level, namespace: group_namespace) }
      let_it_be(:other_issue) { create(:work_item, :group_level, namespace: other_namespace) }

      let(:namespace) { group_namespace }

      before do
        group_namespace.update!(traversal_ids: [new_parent.id, group_namespace.id])
      end

      it 'updates the positioning root for the group work items only', :aggregate_failures do
        expect { update_positioning_namespace_id }
          .to change { positioning_ns_id(group_issue1) }.from(old_parent.id).to(new_parent.id)
          .and change { positioning_ns_id(group_issue2) }.from(old_parent.id).to(new_parent.id)
          .and not_change { positioning_ns_id(other_issue) }
      end
    end

    context 'when namespace is a project namespace' do
      let_it_be_with_reload(:project_namespace) { create(:project_namespace, parent: old_parent) }
      let_it_be(:project_issue) { create(:work_item, project: project_namespace.project) }

      let(:namespace) { project_namespace }

      before do
        project_namespace.update!(traversal_ids: [new_parent.id, project_namespace.id])
      end

      it 'updates the positioning root for the project work items' do
        expect { update_positioning_namespace_id }
          .to change { positioning_ns_id(project_issue) }.from(old_parent.id).to(new_parent.id)
      end
    end

    context 'when namespace is a project under a personal namespace' do
      let_it_be(:user_namespace) { create(:namespace) }
      let_it_be(:personal_project) { create(:project, namespace: user_namespace) }
      let_it_be(:personal_issue) { create(:work_item, project: personal_project) }

      let(:namespace) { personal_project.project_namespace }

      before do
        # Corrupt the trigger-set value so the example proves the refresh actually runs,
        # rather than passing on the value the insert trigger already wrote.
        WorkItems::Position.where(work_item_id: personal_issue.id)
          .update_all(relative_positioning_namespace_id: user_namespace.id)
      end

      it 'positions to the project namespace itself, not the user namespace' do
        expect { update_positioning_namespace_id }
          .to change { positioning_ns_id(personal_issue) }
          .from(user_namespace.id).to(personal_project.project_namespace.id)
      end
    end
  end
end
