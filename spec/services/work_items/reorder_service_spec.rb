# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::ReorderService, feature_category: :team_planning do
  let_it_be(:user)    { create_default(:user) }
  let_it_be(:group)   { create(:group) }
  let_it_be(:project, reload: true) { create(:project, namespace: group) }

  describe '#execute' do
    let_it_be(:item1, reload: true) { create(:work_item, :issue, project: project, relative_position: 10) }
    let_it_be(:item2, reload: true) { create(:work_item, :issue, project: project, relative_position: 20) }
    let_it_be(:item3, reload: true) { create(:work_item, :issue, project: project, relative_position: 30) }

    let(:work_item) { item1 }
    let(:params) { {} }

    subject(:service_result) do
      described_class
        .new(current_user: user, params: params)
        .execute(work_item)
    end

    context 'when ordering work items in a project' do
      before do
        project.add_developer(user)
      end

      it_behaves_like 'reorder service'
    end

    context 'when ordering work items in a group' do
      before_all do
        group.add_developer(user)
      end

      it_behaves_like 'reorder service'

      context 'when ordering work items from other namespaces' do
        let_it_be(:project2) { create(:project) }
        let(:work_item) { create(:work_item, :issue, project: project2) }
        let(:params) { { move_after_id: item2.id, move_before_id: item3.id } }

        it 'does not reorder' do
          expect { service_result }
            .not_to change { work_item.relative_position }

          expect(service_result[:errors])
            .to eq(["You don't have permissions to update this work item"])
        end
      end
    end

    context 'when reordering a work item with no project (group-level)' do
      let_it_be_with_reload(:group_item) do
        create(:work_item, :group_level, namespace: group, relative_position: 100)
      end

      let(:work_item) { group_item }
      let(:params) { { move_before_id: item1.id } }

      before_all do
        group.add_developer(user)
      end

      before do
        allow(user).to receive(:can?).and_call_original
        allow(user).to receive(:can?).with(:update_work_item, work_item).and_return(true)
      end

      it 'passes the work item resource_parent (namespace) as container to UpdateService' do
        expect(::WorkItems::UpdateService).to receive(:new).with(
          hash_including(container: work_item.resource_parent)
        ).and_call_original

        service_result
      end
    end
  end
end
