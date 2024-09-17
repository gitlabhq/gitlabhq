# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::Widgets::Hierarchy, feature_category: :team_planning do
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:task) { create(:work_item, :task, project: project) }
  let_it_be_with_reload(:work_item_parent) { create(:work_item, project: project) }

  describe '.type' do
    subject { described_class.type }

    it { is_expected.to eq(:hierarchy) }
  end

  describe '#type' do
    subject { described_class.new(task).type }

    it { is_expected.to eq(:hierarchy) }
  end

  describe '#parent' do
    let_it_be_with_reload(:parent_link) { create(:parent_link, work_item: task, work_item_parent: work_item_parent) }

    subject { described_class.new(parent_link.work_item).parent }

    it { is_expected.to eq(parent_link.work_item_parent) }
  end

  describe '#has_parent?' do
    subject { described_class.new(task.reload).has_parent? }

    context 'when parent is present' do
      specify do
        create(:parent_link, work_item: task, work_item_parent: work_item_parent)

        is_expected.to eq(true)
      end
    end

    context 'when parent is not present' do
      it { is_expected.to eq(false) }
    end
  end

  describe '#children' do
    let_it_be_with_reload(:parent_link1) { create(:parent_link, work_item_parent: work_item_parent, work_item: task) }
    let_it_be_with_reload(:parent_link2) { create(:parent_link, work_item_parent: work_item_parent) }

    subject { described_class.new(work_item_parent).children }

    it { is_expected.to contain_exactly(parent_link1.work_item, parent_link2.work_item) }

    context 'when ordered by relative position and work_item_id' do
      let_it_be(:oldest_child) { create(:work_item, :task, project: project) }
      let_it_be(:newest_child) { create(:work_item, :task, project: project) }

      let_it_be_with_reload(:link_to_oldest_child) do
        create(:parent_link, work_item_parent: work_item_parent, work_item: oldest_child)
      end

      let_it_be_with_reload(:link_to_newest_child) do
        create(:parent_link, work_item_parent: work_item_parent, work_item: newest_child)
      end

      let(:parent_links_ordered) { [parent_link1, parent_link2, link_to_oldest_child, link_to_newest_child] }

      context 'when children relative positions are nil' do
        it 'orders by work_item_id' do
          is_expected.to eq(parent_links_ordered.map(&:work_item))
        end
      end

      context 'when children relative positions are present' do
        let(:first_position) { 10 }
        let(:second_position) { 20 }
        let(:parent_links_ordered) { [link_to_oldest_child, link_to_newest_child, parent_link1, parent_link2] }

        before do
          link_to_oldest_child.update!(relative_position: first_position)
          link_to_newest_child.update!(relative_position: second_position)
        end

        it 'orders by relative_position and by created_at' do
          is_expected.to eq(parent_links_ordered.map(&:work_item))
        end
      end
    end
  end

  describe '#rolled_up_counts_by_type' do
    let_it_be(:work_item) { create(:work_item, :epic, namespace: group) }
    let_it_be(:sub_epic) { create(:work_item, :epic, :closed, namespace: group) }
    let_it_be(:sub_sub_epic) { create(:work_item, :epic, namespace: group) }
    let_it_be(:sub_epic_2) { create(:work_item, :epic, namespace: group) }
    let_it_be(:sub_issue) { create(:work_item, :issue, :closed, project: project) }
    let_it_be(:sub_issue_2) { create(:work_item, :issue, project: project) }
    let_it_be(:sub_task) { create(:work_item, :task, project: project) }

    subject { described_class.new(work_item).rolled_up_counts_by_type }

    before_all do
      create(:parent_link, work_item_parent: work_item, work_item: sub_epic)
      create(:parent_link, work_item_parent: sub_epic, work_item: sub_sub_epic)
      create(:parent_link, work_item_parent: sub_epic, work_item: sub_issue)
      create(:parent_link, work_item_parent: sub_issue, work_item: sub_task)
      create(:parent_link, work_item_parent: work_item, work_item: sub_epic_2)
      create(:parent_link, work_item_parent: sub_epic_2, work_item: sub_issue_2)
    end

    it 'returns rolled up dates by work item type and state' do
      is_expected.to contain_exactly(
        {
          work_item_type: WorkItems::Type.default_by_type(:epic),
          counts_by_state: { all: 3, opened: 2, closed: 1 }
        },
        {
          work_item_type: WorkItems::Type.default_by_type(:issue),
          counts_by_state: { all: 2, opened: 1, closed: 1 }
        },
        {
          work_item_type: WorkItems::Type.default_by_type(:task),
          counts_by_state: { all: 1, opened: 1, closed: 0 }
        }
      )
    end
  end

  describe '#depth_limit_reached_by_type' do
    let_it_be(:work_item) { create(:work_item, :epic) }
    let_it_be(:hierarchy) { described_class.new(work_item) }
    let_it_be(:descendant_type1) { create(:work_item_type, :epic) }
    let_it_be(:descendant_type2) { create(:work_item_type, :issue) }

    before do
      allow(work_item.work_item_type).to receive(:descendant_types).and_return([descendant_type1, descendant_type2])
    end

    it 'returns an array of hashes with work_item_type and depth_limit_reached' do
      allow(work_item).to receive(:max_depth_reached?).with(descendant_type1).and_return(true)
      allow(work_item).to receive(:max_depth_reached?).with(descendant_type2).and_return(false)

      result = hierarchy.depth_limit_reached_by_type

      expect(result).to contain_exactly(
        { work_item_type: descendant_type1, depth_limit_reached: true },
        { work_item_type: descendant_type2, depth_limit_reached: false }
      )
    end

    it 'calls max_depth_reached? for each descendant type' do
      expect(work_item).to receive(:max_depth_reached?).with(descendant_type1).once
      expect(work_item).to receive(:max_depth_reached?).with(descendant_type2).once

      hierarchy.depth_limit_reached_by_type
    end

    context 'when there are no descendant types' do
      before do
        allow(work_item.work_item_type).to receive(:descendant_types).and_return([])
      end

      it 'returns an empty array' do
        result = hierarchy.depth_limit_reached_by_type

        expect(result).to eq([])
      end
    end
  end
end
