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

  describe '#children' do
    let_it_be_with_reload(:parent_link1) { create(:parent_link, work_item_parent: work_item_parent, work_item: task) }
    let_it_be_with_reload(:parent_link2) { create(:parent_link, work_item_parent: work_item_parent) }

    subject { described_class.new(work_item_parent).children }

    it { is_expected.to contain_exactly(parent_link1.work_item, parent_link2.work_item) }

    context 'with default order by created_at' do
      let_it_be(:oldest_child) { create(:work_item, :task, project: project, created_at: 5.minutes.ago) }

      let_it_be_with_reload(:link_to_oldest_child) do
        create(:parent_link, work_item_parent: work_item_parent, work_item: oldest_child)
      end

      it { is_expected.to eq([link_to_oldest_child, parent_link1, parent_link2].map(&:work_item)) }
    end
  end
end
