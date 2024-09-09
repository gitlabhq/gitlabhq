# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::Widgets::StartAndDueDate, feature_category: :team_planning do
  let(:work_item) { build_stubbed(:work_item, start_date: Date.today, due_date: 1.week.from_now) }

  subject(:widget) { described_class.new(work_item) }

  describe '.type' do
    specify { expect(described_class.type).to eq(:start_and_due_date) }
  end

  describe '.quick_action_params' do
    specify { expect(described_class.quick_action_params).to include(:due_date) }
  end

  describe '#type' do
    specify { expect(widget.type).to eq(:start_and_due_date) }
  end

  describe '#start_date' do
    specify { expect(widget.start_date).to eq(work_item.start_date) }
  end

  describe '#due_date' do
    specify { expect(widget.due_date).to eq(work_item.due_date) }
  end

  context 'when work item has dates_source' do
    let!(:dates_source) do
      work_item.build_dates_source(
        start_date_fixed: work_item.start_date - 1.day,
        due_date_fixed: work_item.due_date + 1.day
      )
    end

    describe '#start_date' do
      specify { expect(widget.start_date).to eq(dates_source.start_date_fixed) }
    end

    describe '#due_date' do
      specify { expect(widget.due_date).to eq(dates_source.due_date_fixed) }
    end
  end
end
