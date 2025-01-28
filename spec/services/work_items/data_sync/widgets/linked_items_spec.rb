# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::DataSync::Widgets::LinkedItems, feature_category: :team_planning do
  let_it_be(:current_user) { create(:user) }
  let_it_be(:group) { create(:group, developers: [current_user]) }
  let_it_be(:project1) { create(:project, group: group) }
  let_it_be(:project2) { create(:project, group: group) }

  let_it_be_with_reload(:target_work_item) { create(:work_item, project: project2) }
  let_it_be_with_reload(:work_item) do
    create(:work_item, :issue, project: project1).tap do |work_item|
      create(:work_item, :issue).tap do |related_work_item|
        create(
          :issue_link, source: work_item, target: related_work_item, link_type: ::Enums::IssuableLink::TYPE_BLOCKS
        )
      end
      create(:work_item, :issue).tap do |related_work_item|
        create(
          :issue_link, source: related_work_item, target: work_item, link_type: ::Enums::IssuableLink::TYPE_RELATES_TO
        )
      end
    end
  end

  let(:params) { { operation: :move } }

  subject(:callback) do
    described_class.new(
      work_item: work_item, target_work_item: target_work_item, current_user: current_user, params: params
    )
  end

  describe '#after_save_commit' do
    context 'when cloning work item' do
      let(:params) { { operation: :clone } }

      it 'does not copy linked_items' do
        expect(callback).not_to receive(:recreate_related_items)
        expect(::IssueLink).not_to receive(:insert_all)

        callback.after_save_commit

        expect(target_work_item.reload.linked_work_items(authorize: false)).to be_empty
      end
    end

    context 'when moving work item' do
      context 'when target work item does not have linked_items widget' do
        before do
          allow(target_work_item).to receive(:get_widget).with(:linked_items).and_return(false)
        end

        it 'does not copy linked_items' do
          expect(callback).not_to receive(:recreate_related_items)
          expect(::IssueLink).not_to receive(:insert_all)

          callback.after_save_commit

          expect(target_work_item.reload.linked_work_items(authorize: false)).to be_empty
        end
      end

      context 'when target work item has linked_items widget' do
        it 'copies linked_items from work_item to target_work_item' do
          expect(callback).to receive(:recreate_related_items).and_call_original
          expect(::IssueLink).to receive(:insert_all).twice.and_call_original

          expected_linked_work_items = work_item.reload.linked_work_items(authorize: false)

          callback.after_save_commit

          target_work_item_linked_work_items = target_work_item.reload.linked_work_items(authorize: false)
          expect(target_work_item_linked_work_items).to match_array(expected_linked_work_items)
        end
      end
    end
  end

  describe '#post_move_cleanup' do
    it 'removes original work item linked_items' do
      expect { callback.post_move_cleanup }.to change { IssueLink.for_source(work_item).count }.from(1).to(0).and(
        change { IssueLink.for_target(work_item).count }.from(1).to(0)
      )
    end
  end
end
