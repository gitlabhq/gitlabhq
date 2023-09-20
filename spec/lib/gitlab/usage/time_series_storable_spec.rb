# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::TimeSeriesStorable, feature_category: :service_ping do
  let(:counter_class) do
    Class.new do
      include Gitlab::Usage::TimeSeriesStorable

      def redis_key(event, date)
        key = apply_time_aggregation(event, date)
        "#{key}:"
      end
    end
  end

  let(:counter_instance) { counter_class.new }

  describe '#apply_time_aggregation' do
    let(:key) { "key3" }
    let(:time) { Date.new(2023, 5, 1) }

    it 'returns proper key for given time' do
      expect(counter_instance.apply_time_aggregation(key, time)).to eq("key3-2023-18")
    end
  end

  describe '#keys_for_aggregation' do
    let(:result) { counter_instance.keys_for_aggregation(**params) }
    let(:params) { base_params }
    let(:base_params) { { events: events, start_date: start_date, end_date: end_date } }
    let(:events) { %w[event1 event2] }
    let(:start_date) { Date.new(2023, 4, 1) }
    let(:end_date) { Date.new(2023, 4, 15) }

    it 'returns proper keys' do
      expect(result).to match_array(["event1-2023-13:", "event1-2023-14:", "event2-2023-13:", "event2-2023-14:"])
    end
  end
end
