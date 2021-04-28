# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Analytics::CycleAnalytics::Sorting do
  let(:stage) { build(:cycle_analytics_project_stage, start_event_identifier: :merge_request_created, end_event_identifier: :merge_request_merged) }

  subject(:order_values) { described_class.new(query: MergeRequest.joins(:metrics), stage: stage).apply(sort, direction).order_values }

  context 'when invalid sorting params are given' do
    let(:sort) { :unknown_sort }
    let(:direction) { :unknown_direction }

    it 'falls back to end_event DESC sorting' do
      expect(order_values).to eq([stage.end_event.timestamp_projection.desc])
    end
  end

  context 'sorting end_event' do
    let(:sort) { :end_event }

    context 'direction desc' do
      let(:direction) { :desc }

      specify do
        expect(order_values).to eq([stage.end_event.timestamp_projection.desc])
      end
    end

    context 'direction asc' do
      let(:direction) { :asc }

      specify do
        expect(order_values).to eq([stage.end_event.timestamp_projection.asc])
      end
    end
  end

  context 'sorting duration' do
    let(:sort) { :duration }

    context 'direction desc' do
      let(:direction) { :desc }

      specify do
        expect(order_values).to eq([Arel::Nodes::Subtraction.new(stage.end_event.timestamp_projection, stage.start_event.timestamp_projection).desc])
      end
    end

    context 'direction asc' do
      let(:direction) { :asc }

      specify do
        expect(order_values).to eq([Arel::Nodes::Subtraction.new(stage.end_event.timestamp_projection, stage.start_event.timestamp_projection).asc])
      end
    end
  end
end
