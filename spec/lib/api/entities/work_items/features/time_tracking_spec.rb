# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Entities::WorkItems::Features::TimeTracking, feature_category: :portfolio_management do
  it_behaves_like 'work item widget entity parity',
    described_class,
    Types::WorkItems::Widgets::TimeTracking::TimeTrackingType,
    exceptions: %w[widget_definition]

  describe '#as_json' do
    let(:user) { build_stubbed(:user) }
    let(:timelog1) do
      instance_double(
        Timelog,
        id: 1,
        spent_at: Time.zone.parse('2024-01-15T10:00:00Z'),
        created_at: Time.zone.parse('2024-01-14T08:00:00Z'),
        time_spent: 3600,
        user: user,
        summary: 'Reviewed MR'
      )
    end

    let(:timelog2) do
      instance_double(
        Timelog,
        id: 2,
        spent_at: Time.zone.parse('2024-01-15T14:00:00Z'),
        created_at: Time.zone.parse('2024-01-15T13:00:00Z'),
        time_spent: 900,
        user: user,
        summary: 'Fixed bug'
      )
    end

    let(:widget) do
      instance_double(
        WorkItems::Widgets::TimeTracking,
        time_estimate: 12600,
        total_time_spent: 4500,
        human_time_estimate: '3h 30m',
        human_total_time_spent: '1h 15m',
        timelogs: [timelog1, timelog2]
      )
    end

    subject(:representation) { described_class.new(widget).as_json }

    it 'exposes the time tracking fields' do
      aggregate_failures do
        expect(representation[:time_estimate]).to eq(12600)
        expect(representation[:total_time_spent]).to eq(4500)
        expect(representation[:human_readable_attributes]).to include(
          time_estimate: '3h 30m',
          total_time_spent: '1h 15m'
        )
        expect(representation[:timelogs].first).to include(
          id: 1,
          time_spent: 3600,
          summary: 'Reviewed MR'
        )
      end
    end

    context 'when values are nil' do
      let(:widget) do
        instance_double(
          WorkItems::Widgets::TimeTracking,
          time_estimate: nil,
          total_time_spent: nil,
          human_time_estimate: nil,
          human_total_time_spent: nil,
          timelogs: []
        )
      end

      it 'exposes nil values' do
        expect(representation[:time_estimate]).to be_nil
        expect(representation[:total_time_spent]).to eq(0)
        expect(representation[:timelogs]).to be_empty
      end
    end
  end
end
