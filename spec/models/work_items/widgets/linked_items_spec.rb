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

  describe '#type' do
    subject { described_class.new(work_item).type }

    it { is_expected.to eq(:linked_items) }
  end

  describe '#related_issues' do
    it { expect(described_class.new(work_item).related_issues(user)).to eq(work_item.related_issues(user)) }
  end
end
