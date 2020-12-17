# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'aggregated metrics' do
  RSpec::Matchers.define :be_known_event do
    match do |event|
      Gitlab::UsageDataCounters::HLLRedisCounter.known_event?(event)
    end

    failure_message do |event|
      "Event with name: `#{event}` can not be found within `#{Gitlab::UsageDataCounters::HLLRedisCounter::KNOWN_EVENTS_PATH}`"
    end
  end

  let_it_be(:known_events) do
    Gitlab::UsageDataCounters::HLLRedisCounter.known_events
  end

  Gitlab::UsageDataCounters::HLLRedisCounter.aggregated_metrics.tap do |aggregated_metrics|
    it 'all events has unique name' do
      event_names = aggregated_metrics&.map { |event| event[:name] }

      expect(event_names).to eq(event_names&.uniq)
    end

    aggregated_metrics&.each do |aggregate|
      context "for #{aggregate[:name]} aggregate of #{aggregate[:events].join(' ')}" do
        let_it_be(:events_records) { known_events.select { |event| aggregate[:events].include?(event[:name]) } }

        it "only refers to known events" do
          expect(aggregate[:events]).to all be_known_event
        end

        it "has expected structure" do
          expect(aggregate.keys).to include(*%w[name operator events])
        end

        it "uses allowed aggregation operators" do
          expect(Gitlab::UsageDataCounters::HLLRedisCounter::ALLOWED_METRICS_AGGREGATIONS).to include aggregate[:operator]
        end

        it "uses events from the same Redis slot" do
          event_slots = events_records.map { |event| event[:redis_slot] }.uniq

          expect(event_slots).to contain_exactly(be_present)
        end

        it "uses events with the same aggregation period" do
          event_slots = events_records.map { |event| event[:aggregation] }.uniq

          expect(event_slots).to contain_exactly(be_present)
        end
      end
    end
  end
end
