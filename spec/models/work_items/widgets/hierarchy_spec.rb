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
end
