# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::Widgets::Assignees do
  let_it_be(:work_item) { create(:work_item, assignees: [create(:user)]) }

  describe '.type' do
    subject { described_class.type }

    it { is_expected.to eq(:assignees) }
  end

  describe '#type' do
    subject { described_class.new(work_item).type }

    it { is_expected.to eq(:assignees) }
  end

  describe '#assignees' do
    subject { described_class.new(work_item).assignees }

    it { is_expected.to eq(work_item.assignees) }
  end

  describe '#allows_multiple_assignees?' do
    subject { described_class.new(work_item).allows_multiple_assignees? }

    it { is_expected.to eq(work_item.allows_multiple_assignees?) }
  end
end
