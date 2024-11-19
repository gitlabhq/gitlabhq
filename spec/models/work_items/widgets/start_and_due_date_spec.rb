# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::Widgets::StartAndDueDate, feature_category: :team_planning do
  let(:work_item) { nil }

  subject(:widget) { described_class.new(work_item) }

  describe '.type' do
    specify { expect(described_class.type).to eq(:start_and_due_date) }
  end

  describe '#type' do
    specify { expect(widget.type).to eq(:start_and_due_date) }
  end

  describe '.quick_action_params' do
    specify { expect(described_class.quick_action_params).to contain_exactly(:due_date) }
  end

  describe '.quick_action_commands' do
    specify { expect(described_class.quick_action_commands).to contain_exactly(:due, :remove_due_date) }
  end

  describe '#fixed?' do
    specify { expect(widget.fixed?).to be(true) }
  end

  describe '#can_rollup?' do
    specify { expect(widget.can_rollup?).to be(false) }
  end

  context 'when on FOSS', unless: Gitlab.ee? do
    context 'and work_item does not exist' do
      describe '#start_date' do
        specify { expect(widget.start_date).to be_nil }
      end

      describe '#due_date' do
        specify { expect(widget.due_date).to be_nil }
      end
    end

    context 'and work_item exists' do
      let(:work_item) { build_stubbed(:work_item, start_date: Time.zone.today, due_date: 1.week.from_now) }

      context 'and work_item does not have a dates_source' do
        describe '#start_date' do
          specify { expect(widget.start_date).to eq(work_item.start_date) }
        end

        describe '#due_date' do
          specify { expect(widget.due_date).to eq(work_item.due_date) }
        end
      end

      context 'and work_item does have an empty dates_source' do
        before do
          work_item.build_dates_source
        end

        describe '#start_date' do
          specify { expect(widget.start_date).to eq(work_item.start_date) }
        end

        describe '#due_date' do
          specify { expect(widget.due_date).to eq(work_item.due_date) }
        end
      end

      context 'and work_item does have a non empty dates_source' do
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
  end
end
