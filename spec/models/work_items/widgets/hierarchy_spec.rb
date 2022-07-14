# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::Widgets::Hierarchy do
  let_it_be(:work_item) { create(:work_item) }

  describe '.type' do
    subject { described_class.type }

    it { is_expected.to eq(:hierarchy) }
  end

  describe '#type' do
    subject { described_class.new(work_item).type }

    it { is_expected.to eq(:hierarchy) }
  end

  describe '#parent' do
    let_it_be(:parent_link) { create(:parent_link) }

    subject { described_class.new(parent_link.work_item).parent }

    it { is_expected.to eq parent_link.work_item_parent }

    context 'when work_items flag is disabled' do
      before do
        stub_feature_flags(work_items: false)
      end

      it { is_expected.to be_nil }
    end
  end

  describe '#children' do
    let_it_be(:parent_link1) { create(:parent_link, work_item_parent: work_item) }
    let_it_be(:parent_link2) { create(:parent_link, work_item_parent: work_item) }

    subject { described_class.new(work_item).children }

    it { is_expected.to match_array([parent_link1.work_item, parent_link2.work_item]) }

    context 'when work_items flag is disabled' do
      before do
        stub_feature_flags(work_items: false)
      end

      it { is_expected.to be_empty }
    end
  end
end
