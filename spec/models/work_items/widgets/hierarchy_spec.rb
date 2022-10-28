# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::Widgets::Hierarchy do
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:task) { create(:work_item, :task, project: project) }
  let_it_be(:work_item_parent) { create(:work_item, project: project) }

  describe '.type' do
    subject { described_class.type }

    it { is_expected.to eq(:hierarchy) }
  end

  describe '#type' do
    subject { described_class.new(task).type }

    it { is_expected.to eq(:hierarchy) }
  end

  describe '#parent' do
    let_it_be(:parent_link) { create(:parent_link, work_item: task, work_item_parent: work_item_parent).reload }

    subject { described_class.new(parent_link.work_item).parent }

    it { is_expected.to eq(parent_link.work_item_parent) }
  end

  describe '#children' do
    let_it_be(:parent_link1) { create(:parent_link, work_item_parent: work_item_parent, work_item: task).reload }
    let_it_be(:parent_link2) { create(:parent_link, work_item_parent: work_item_parent).reload }

    subject { described_class.new(work_item_parent).children }

    it { is_expected.to contain_exactly(parent_link1.work_item, parent_link2.work_item) }
  end
end
