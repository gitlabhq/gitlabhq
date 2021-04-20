# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Aggregates::Sources::Calculations::Intersection do
  let_it_be(:recorded_at) { Time.current.to_i }
  let_it_be(:start_date) { 4.weeks.ago.to_date }
  let_it_be(:end_date) { Date.current }

  shared_examples 'aggregated_metrics_data with source' do
    context 'with AND operator' do
      let(:params) { { start_date: start_date, end_date: end_date, recorded_at: recorded_at } }

      context 'with even number of metrics' do
        it 'calculates intersection correctly', :aggregate_failures do
          # gmau_1 data is as follow
          # |A| => 4
          expect(source).to receive(:calculate_metrics_union).with(params.merge(metric_names: 'event3')).and_return(4)
          # |B| => 6
          expect(source).to receive(:calculate_metrics_union).with(params.merge(metric_names: 'event5')).and_return(6)
          # |A + B| => 8
          expect(source).to receive(:calculate_metrics_union).with(params.merge(metric_names: %w[event3 event5])).and_return(8)
          # Exclusion inclusion principle formula to calculate intersection of 2 sets
          # |A & B| = (|A| + |B|) - |A + B| => (4 + 6) - 8 => 2
          expect(source.calculate_metrics_intersections(metric_names: %w[event3 event5], start_date: start_date, end_date: end_date, recorded_at: recorded_at)).to eq(2)
        end
      end

      context 'with odd number of metrics' do
        it 'calculates intersection correctly', :aggregate_failures do
          # gmau_2 data is as follow:
          # |A| => 2
          expect(source).to receive(:calculate_metrics_union).with(params.merge(metric_names: 'event1')).and_return(2)
          # |B| => 3
          expect(source).to receive(:calculate_metrics_union).with(params.merge(metric_names: 'event2')).and_return(3)
          # |C| => 5
          expect(source).to receive(:calculate_metrics_union).with(params.merge(metric_names: 'event3')).and_return(5)

          # |A + B| => 4 therefore |A & B| = (|A| + |B|) - |A + B| =>  2 + 3 - 4 => 1
          expect(source).to receive(:calculate_metrics_union).with(params.merge(metric_names: %w[event1 event2])).and_return(4)
          # |A + C| => 6 therefore |A & C| = (|A| + |C|) - |A + C| =>  2 + 5 - 6  => 1
          expect(source).to receive(:calculate_metrics_union).with(params.merge(metric_names: %w[event1 event3])).and_return(6)
          # |B + C| => 7 therefore |B & C| = (|B| + |C|) - |B + C| => 3 + 5 - 7 => 1
          expect(source).to receive(:calculate_metrics_union).with(params.merge(metric_names: %w[event2 event3])).and_return(7)
          # |A + B + C| => 8
          expect(source).to receive(:calculate_metrics_union).with(params.merge(metric_names: %w[event1 event2 event3])).and_return(8)
          # Exclusion inclusion principle formula to calculate intersection of 3 sets
          # |A & B & C| = (|A & B| + |A & C| + |B & C|) - (|A| + |B| + |C|)  + |A + B + C|
          # (1 + 1 + 1) - (2 + 3 + 5) + 8 => 1
          expect(source.calculate_metrics_intersections(metric_names: %w[event1 event2 event3], start_date: start_date, end_date: end_date, recorded_at: recorded_at)).to eq(1)
        end
      end
    end
  end

  describe '.aggregated_metrics_data' do
    let(:source) do
      Class.new do
        extend Gitlab::Usage::Metrics::Aggregates::Sources::Calculations::Intersection
      end
    end

    it 'caches intermediate operations', :aggregate_failures do
      events = %w[event1 event2 event3 event5]

      params = { start_date: start_date, end_date: end_date, recorded_at: recorded_at }

      events.each do |event|
        expect(source).to receive(:calculate_metrics_union)
                                       .with(params.merge(metric_names: event))
                                       .once
                                       .and_return(0)
      end

      2.upto(4) do |subset_size|
        events.combination(subset_size).each do |events|
          expect(source).to receive(:calculate_metrics_union)
                                         .with(params.merge(metric_names: events))
                                         .once
                                         .and_return(0)
        end
      end

      expect(source.calculate_metrics_intersections(metric_names: events, start_date: start_date, end_date: end_date, recorded_at: recorded_at)).to eq(0)
    end

    it_behaves_like 'aggregated_metrics_data with source'
  end
end
