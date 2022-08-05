# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::Widgets::Labels do
  let_it_be(:work_item) { create(:work_item, labels: [create(:label)]) }

  describe '.type' do
    subject { described_class.type }

    it { is_expected.to eq(:labels) }
  end

  describe '#type' do
    subject { described_class.new(work_item).type }

    it { is_expected.to eq(:labels) }
  end

  describe '#labels' do
    subject { described_class.new(work_item).labels }

    it { is_expected.to eq(work_item.labels) }
  end

  describe '#allowScopedLabels' do
    subject { described_class.new(work_item).allows_scoped_labels? }

    it { is_expected.to eq(work_item.allows_scoped_labels?) }
  end
end
