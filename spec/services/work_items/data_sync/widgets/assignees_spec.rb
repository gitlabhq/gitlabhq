# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::DataSync::Widgets::Assignees, feature_category: :team_planning do
  let_it_be(:current_user) { create(:user) }
  let_it_be(:assignee1) { create(:user) }
  let_it_be(:assignee2) { create(:user) }
  let_it_be_with_reload(:work_item) { create(:work_item, assignees: [assignee1, assignee2]) }
  let_it_be_with_reload(:target_work_item) { create(:work_item) }
  let(:params) { {} }

  subject(:callback) do
    described_class.new(
      work_item: work_item, target_work_item: target_work_item, current_user: current_user, params: params
    )
  end

  describe '#before_create' do
    context 'when target work item has assignees widget' do
      before do
        allow(target_work_item).to receive(:get_widget).with(:assignees).and_return(true)
      end

      it 'copies assignee_ids from work_item to target_work_item' do
        expect(callback).to receive(:new_work_item_assignees).and_call_original
        expect(::IssueAssignee).to receive(:insert_all).and_call_original

        callback.after_create

        expect(target_work_item.reload.assignees).to match_array([assignee1, assignee2])
      end
    end

    context 'when target work item does not have assignees widget' do
      before do
        target_work_item.reload
        allow(target_work_item).to receive(:get_widget).with(:assignees).and_return(false)
      end

      it 'does not copy assignee_ids' do
        expect(callback).not_to receive(:new_work_item_assignees)
        expect(::IssueAssignee).not_to receive(:insert_all)

        callback.after_create

        expect(target_work_item.reload.assignees).to be_empty
      end
    end
  end

  describe '#post_move_cleanup' do
    it 'is defined and can be called' do
      expect { callback.post_move_cleanup }.not_to raise_error
    end

    it 'removes original work item assignees' do
      callback.post_move_cleanup

      expect(work_item.assignee_ids).to be_empty
    end
  end
end
