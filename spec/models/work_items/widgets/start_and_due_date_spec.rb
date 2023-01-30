# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::Widgets::StartAndDueDate do
  let_it_be(:work_item) { create(:work_item, start_date: Date.today, due_date: 1.week.from_now) }

  describe '.type' do
    subject { described_class.type }

    it { is_expected.to eq(:start_and_due_date) }
  end

  describe '.quick_action_params' do
    subject { described_class.quick_action_params }

    it { is_expected.to include(:due_date) }
  end

  describe '#type' do
    subject { described_class.new(work_item).type }

    it { is_expected.to eq(:start_and_due_date) }
  end

  describe '#start_date' do
    subject { described_class.new(work_item).start_date }

    it { is_expected.to eq(work_item.start_date) }
  end

  describe '#due_date' do
    subject { described_class.new(work_item).due_date }

    it { is_expected.to eq(work_item.due_date) }
  end
end
