# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::DataSync::Widgets::Labels, feature_category: :team_planning do
  let_it_be(:current_user) { create(:user) }
  let_it_be(:group) { create(:group, developers: [current_user]) }
  let_it_be(:project1) { create(:project, group: group) }
  let_it_be(:project2) { create(:project, group: group) }
  let_it_be(:group_label) { create(:group_label, group: group) }
  let_it_be(:project_label) { create(:label, project: project1) }

  let_it_be_with_reload(:work_item) { create(:work_item, project: project1, labels: [group_label, project_label]) }
  let_it_be_with_reload(:target_work_item) { create(:work_item, project: project2) }

  let(:params) { {} }

  subject(:callback) do
    described_class.new(
      work_item: work_item, target_work_item: target_work_item, current_user: current_user, params: params
    )
  end

  describe '#after_save_commit' do
    context 'when target work item does not have labels widget' do
      before do
        allow(target_work_item).to receive(:get_widget).with(:labels).and_return(false)
      end

      it 'does not copy labels' do
        expect(callback).not_to receive(:new_work_item_label_links)
        expect(::LabelLink).not_to receive(:insert_all)

        expect { callback.after_save_commit }.not_to change { ::ResourceLabelEvent.count }

        expect(target_work_item.reload.labels).to be_empty
      end
    end

    context 'when target work item has labels widget' do
      it 'copies labels from work_item to target_work_item' do
        expect(callback).to receive(:new_work_item_label_links).and_call_original
        expect(::LabelLink).to receive(:insert_all).and_call_original

        # adds an event about project level label being removed,
        # because it is a project level label that is not found in the new project.
        expect { callback.after_save_commit }.to change { ::ResourceLabelEvent.count }.by(1)

        expect(target_work_item.reload.labels).to match_array([group_label])
      end
    end
  end

  describe '#post_move_cleanup' do
    it 'removes original work item labels' do
      expect { callback.post_move_cleanup }.to change { work_item.reload.labels.count }.from(2).to(0)
    end
  end
end
