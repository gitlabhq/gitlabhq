# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::BulkUpdateService, feature_category: :team_planning do
  let_it_be(:developer) { create(:user) }
  let_it_be(:guest) { create(:user) }
  let_it_be(:user) { create(:user) }
  let_it_be(:private_group) { create(:group, :private) }
  let_it_be(:parent_group) { create(:group, :private, developers: developer, guests: guest) }
  let_it_be(:group) { create(:group, :private, parent: parent_group) }
  let_it_be(:project) { create(:project, :private, group: group) }
  let_it_be(:label1) { create(:group_label, group: parent_group) }
  let_it_be(:label2) { create(:group_label, group: parent_group) }
  let_it_be(:label3) { create(:group_label, group: private_group) }
  let_it_be_with_reload(:work_item1) { create(:work_item, :group_level, namespace: group, labels: [label1]) }
  let_it_be_with_reload(:work_item2) { create(:work_item, project: project, labels: [label1]) }
  let_it_be_with_reload(:work_item3) { create(:work_item, :group_level, namespace: parent_group, labels: [label1]) }
  let_it_be_with_reload(:work_item4) { create(:work_item, :group_level, namespace: private_group, labels: [label3]) }
  let_it_be_with_reload(:work_item5) { create(:work_item, :group_level, namespace: group, labels: [label1]) }

  let(:updatable_work_items) { [work_item1, work_item2, work_item3, work_item4] }
  let(:updatable_work_item_ids) { updatable_work_items.map(&:id) }
  let(:widget_params) do
    {
      labels_widget: {
        add_label_ids: [label2.id],
        remove_label_ids: [label1.id, label3.id]
      }
    }
  end

  subject(:service_result) do
    described_class.new(
      parent: parent,
      current_user: current_user,
      work_item_ids: updatable_work_item_ids,
      widget_params: widget_params
    ).execute
  end

  context 'when parent is a group' do
    let(:parent) { group }

    context 'when the user can read the parent' do
      context 'when the user can update the work item' do
        let(:current_user) { developer }

        it { is_expected.to be_success }

        it 'updates all work items scoped to the group hierarchy' do
          expect do
            service_result
          end.to not_change { work_item1.reload.label_ids }.from([label1.id])
            .and change { work_item2.reload.label_ids }.from([label1.id]).to([label2.id])
            .and not_change { work_item3.reload.label_ids }.from([label1.id])
            .and not_change { work_item4.reload.label_ids }.from([label3.id])
            .and not_change { work_item5.reload.label_ids }.from([label1.id])
        end

        it 'returns update count' do
          expect(service_result[:updated_work_item_count]).to eq(1)
        end

        context 'with EE license', if: Gitlab.ee? do
          before do
            stub_licensed_features(epics: true)
          end

          it 'updates all work items scoped to the group hierarchy' do
            expect do
              service_result
            end.to change { work_item1.reload.label_ids }.from([label1.id]).to([label2.id])
              .and change { work_item2.reload.label_ids }.from([label1.id]).to([label2.id])
              .and not_change { work_item3.reload.label_ids }.from([label1.id])
              .and not_change { work_item4.reload.label_ids }.from([label3.id])
              .and not_change { work_item5.reload.label_ids }.from([label1.id])
          end

          it 'returns update count' do
            expect(service_result[:updated_work_item_count]).to eq(2)
          end
        end
      end

      context 'when the user cannot update the work item' do
        let(:current_user) { guest }

        it 'does not update work items' do
          expect do
            service_result
          end.to not_change { work_item1.reload.label_ids }.from([label1.id])
            .and not_change { work_item2.reload.label_ids }.from([label1.id])
            .and not_change { work_item3.reload.label_ids }.from([label1.id])
            .and not_change { work_item4.reload.label_ids }.from([label3.id])
            .and not_change { work_item5.reload.label_ids }.from([label1.id])
        end

        it 'returns a 0 update count' do
          expect(service_result[:updated_work_item_count]).to eq(0)
        end
      end
    end

    context 'when the user cannot read the parent' do
      let(:current_user) { user }

      it { is_expected.to be_error }

      it 'returns authorization as the reason for failure' do
        expect(service_result.reason).to eq(:authorization)
      end
    end
  end

  context 'when parent is a project' do
    let(:parent) { project }

    context 'when the user can read the parent' do
      let(:current_user) { developer }

      it { is_expected.to be_success }

      it 'updates all work items scoped to the project' do
        expect do
          service_result
        end.to not_change { work_item1.reload.label_ids }.from([label1.id])
          .and change { work_item2.reload.label_ids }.from([label1.id]).to([label2.id])
          .and not_change { work_item3.reload.label_ids }.from([label1.id])
          .and not_change { work_item4.reload.label_ids }.from([label3.id])
          .and not_change { work_item5.reload.label_ids }.from([label1.id])
      end

      it 'returns update count' do
        expect(service_result[:updated_work_item_count]).to eq(1)
      end

      context 'when the user cannot update the work item' do
        let(:current_user) { guest }

        it 'does not update work items' do
          expect do
            service_result
          end.to not_change { work_item1.reload.label_ids }.from([label1.id])
            .and not_change { work_item2.reload.label_ids }.from([label1.id])
            .and not_change { work_item3.reload.label_ids }.from([label1.id])
            .and not_change { work_item4.reload.label_ids }.from([label3.id])
            .and not_change { work_item5.reload.label_ids }.from([label1.id])
        end

        it 'returns a 0 update count' do
          expect(service_result[:updated_work_item_count]).to eq(0)
        end
      end
    end

    context 'when the user cannot read the parent' do
      let(:current_user) { user }

      it { is_expected.to be_error }

      it 'returns authorization as the reason for failure' do
        expect(service_result.reason).to eq(:authorization)
      end
    end
  end
end
