# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::Widgets::LinkedItems, feature_category: :portfolio_management do
  let_it_be(:user) { create(:user) }
  let_it_be(:work_item) { create(:work_item) }
  let_it_be(:work_item_link) { create(:work_item_link, source: work_item) }

  describe '.type' do
    subject { described_class.type }

    it { is_expected.to eq(:linked_items) }
  end

  describe '.quick_action_commands' do
    specify do
      expect(described_class.quick_action_commands)
        .to contain_exactly(:blocks, :blocked_by, :relate, :unlink)
    end
  end

  describe '#type' do
    subject { described_class.new(work_item).type }

    it { is_expected.to eq(:linked_items) }
  end

  describe '#linked_work_items' do
    it { expect(described_class.new(work_item).linked_work_items(user)).to eq(work_item.linked_work_items(user)) }
  end
end
