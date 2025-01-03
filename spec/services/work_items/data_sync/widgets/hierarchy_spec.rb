# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::DataSync::Widgets::Hierarchy, feature_category: :team_planning do
  let_it_be(:current_user) { create(:user) }
  let_it_be(:target_work_item) { create(:work_item, :issue) }
  let_it_be(:work_item) do
    create(:work_item, :issue).tap do |parent|
      tasks = create_list(:work_item, 2, :task, project: parent.project)
      tasks.each do |child|
        create(:parent_link, work_item: child, work_item_parent: parent)
      end
    end
  end

  let(:params) { { operation: :move } }

  before_all do
    work_item.project.add_developer(current_user)
    target_work_item.project.add_developer(current_user)
  end

  subject(:callback) do
    described_class.new(
      work_item: work_item, target_work_item: target_work_item, current_user: current_user, params: params
    )
  end

  describe '#after_save_commit' do
    context 'when target work item has hierarchy widget' do
      before do
        allow(target_work_item).to receive(:get_widget).with(:hierarchy).and_return(true)
      end

      it 'copies hierarchy data from work_item to target_work_item', :aggregate_failures do
        expect(callback).to receive(:handle_parent).and_call_original
        expect(callback).to receive(:handle_children).and_call_original

        expected_child_items_titles = work_item.work_item_children.map(&:title)

        callback.after_save_commit

        # these are the newly copied child records
        new_children = target_work_item.reload.work_item_children.where(moved_to_id: nil)
        # these are the originally re-linked child records from source work item that are closed upon move.
        moved_children = target_work_item.reload.work_item_children.where.not(moved_to_id: nil)

        expect(new_children.size).to eq(2)
        expect(new_children.map(&:title)).to match_array(expected_child_items_titles)
        expect(new_children.map(&:state)).to match_array(%w[opened opened])
        expect(new_children.map(&:namespace_id).uniq).to match_array([target_work_item.namespace_id])

        expect(moved_children.size).to eq(2)
        expect(moved_children.map(&:title)).to match_array(expected_child_items_titles)
        expect(moved_children.map(&:state)).to match_array(%w[closed closed])
        expect(moved_children.map(&:namespace_id).uniq).to match_array([work_item.namespace_id])
        # original child items now point to the moved items.
        expect(moved_children.map(&:moved_to_id)).to match_array(new_children.map(&:id))
        # new target work item and its 2 child tasks are located within new namespace
        expect(target_work_item.namespace.work_items.count).to eq(3)

        # child items are relinked in `after_save_commit`
        expect(work_item.reload.work_item_children).to be_empty
      end
    end

    context 'when target work item does not have hierarchy widget' do
      before do
        target_work_item.reload
        allow(target_work_item).to receive(:get_widget).with(:hierarchy).and_return(false)
      end

      it 'does not copy hierarchy data' do
        expect(callback).not_to receive(:new_work_item_child_link)
        expect(::WorkItems::ParentLink).not_to receive(:upsert_all)

        callback.after_create

        expect(target_work_item.reload.work_item_children).to be_empty
      end
    end
  end

  describe '#post_move_cleanup' do
    it 'is defined and can be called' do
      expect { callback.post_move_cleanup }.not_to raise_error
    end
  end
end
