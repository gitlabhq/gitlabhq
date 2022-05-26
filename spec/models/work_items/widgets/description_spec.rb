# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::Widgets::Description do
  let_it_be(:work_item) { create(:work_item, description: '# Title') }

  describe '.type' do
    subject { described_class.type }

    it { is_expected.to eq(:description) }
  end

  describe '#type' do
    subject { described_class.new(work_item).type }

    it { is_expected.to eq(:description) }
  end

  describe '#description' do
    subject { described_class.new(work_item).description }

    it { is_expected.to eq(work_item.description) }
  end
end
