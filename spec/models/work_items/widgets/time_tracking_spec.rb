# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::Widgets::TimeTracking, feature_category: :team_planning do
  let_it_be(:work_item) { create(:work_item, time_estimate: 12.hours) }
  let_it_be(:timelog1) { create(:timelog, issue: work_item, time_spent: 1.hour.to_i) }
  let_it_be(:timelog2) { create(:timelog, issue: work_item, time_spent: 2.hours.to_i) }

  describe '.quick_action_params' do
    subject { described_class.quick_action_params }

    it { is_expected.to contain_exactly(:time_estimate, :spend_time) }
  end

  describe '.quick_action_commands' do
    subject { described_class.quick_action_commands }

    it 'lists all available quick actions' do
      is_expected.to contain_exactly(
        :estimate, :estimate_time, :remove_estimate,
        :remove_time_estimate, :remove_time_spent, :spend, :spend_time, :spent
      )
    end
  end

  describe '.type' do
    it { expect(described_class.type).to eq(:time_tracking) }
  end

  describe '#type' do
    it { expect(described_class.new(work_item).type).to eq(:time_tracking) }
  end

  describe 'time tracking data' do
    it { expect(described_class.new(work_item).time_estimate).to eq(work_item.time_estimate) }
    it { expect(described_class.new(work_item).total_time_spent).to eq(3.hours) }
    it { expect(described_class.new(work_item).timelogs.map(&:id)).to match_array([timelog1.id, timelog2.id]) }
  end
end
