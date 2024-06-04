# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::EventSelectionRule, feature_category: :service_ping do
  describe '#redis_key_for_date' do
    let(:date) { Date.new(2023, 10, 19) }
    let(:filter) { nil }
    let(:event_selection_rule) do
      described_class.new(
        name: 'example_event',
        time_framed: false,
        filter: filter
      )
    end

    context 'without a filter' do
      it 'returns the key name' do
        expect(event_selection_rule.redis_key_for_date).to eq('{event_counters}_example_event')
      end
    end

    context 'with a single property filter' do
      let(:filter) { { label: 'npm' } }

      it 'returns the correct key with filter' do
        expect(event_selection_rule.redis_key_for_date).to eq('{event_counters}_example_event-filter:[label:npm]')
      end
    end

    context 'with a multi property filter that is unordered' do
      let(:filter) { { property: 'deploy_token', label: 'npm' } }

      it 'returns the correct key with filter' do
        expect(event_selection_rule.redis_key_for_date)
          .to eq('{event_counters}_example_event-filter:[label:npm,property:deploy_token]')
      end
    end

    context "when time framed" do
      let(:event_selection_rule) { described_class.new(name: 'my_event', time_framed: true) }

      it 'adds the key prefix and suffix to the event name' do
        expect(event_selection_rule.redis_key_for_date(date)).to eq("{event_counters}_my_event-2023-42")
      end
    end
  end

  describe '#redis_keys_for_time_frame' do
    around do |example|
      reference_time = Time.utc(2024, 6, 1)
      travel_to(reference_time) { example.run }
    end

    context 'without a filter' do
      let(:time_framed) { true }
      let(:event_selection_rule) do
        described_class.new(
          name: 'an_event',
          time_framed: time_framed,
          filter: {}
        )
      end

      context 'when time_frame is "all"' do
        let(:time_framed) { false }

        it 'returns an array with a single redis key' do
          expect(event_selection_rule.redis_keys_for_time_frame('all')).to eq(['{event_counters}_an_event'])
        end
      end

      context 'when time_frame is "7d"' do
        it 'returns an array with a single redis keys for correct week' do
          expect(event_selection_rule.redis_keys_for_time_frame('7d')).to eq(["{event_counters}_an_event-2024-21"])
        end
      end

      context 'when time_frame is "28d"' do
        it 'returns an array with a keys for the last 4 full weeks' do
          expect(event_selection_rule.redis_keys_for_time_frame('28d')).to eq(
            [
              "{event_counters}_an_event-2024-18",
              "{event_counters}_an_event-2024-19",
              "{event_counters}_an_event-2024-20",
              "{event_counters}_an_event-2024-21"
            ]
          )
        end
      end
    end

    context 'with a filter' do
      let(:time_framed) { true }
      let(:event_selection_rule) do
        described_class.new(
          name: 'an_event',
          time_framed: time_framed,
          filter: { label: 'foo' }
        )
      end

      context 'when time_frame is "all"' do
        let(:time_framed) { false }

        it 'returns an array with a single redis key' do
          expect(event_selection_rule.redis_keys_for_time_frame('all'))
            .to eq(['{event_counters}_an_event-filter:[label:foo]'])
        end
      end

      context 'when time_frame is "7d"' do
        it 'returns an array with a single redis keys for correct week' do
          expect(event_selection_rule.redis_keys_for_time_frame('7d'))
            .to eq(["{event_counters}_an_event-filter:[label:foo]-2024-21"])
        end
      end

      context 'when time_frame is "28d"' do
        it 'returns an array with a keys for the last 4 full weeks' do
          expect(event_selection_rule.redis_keys_for_time_frame('28d')).to eq(
            [
              "{event_counters}_an_event-filter:[label:foo]-2024-18",
              "{event_counters}_an_event-filter:[label:foo]-2024-19",
              "{event_counters}_an_event-filter:[label:foo]-2024-20",
              "{event_counters}_an_event-filter:[label:foo]-2024-21"
            ]
          )
        end
      end
    end
  end

  describe 'object equality - #eql' do
    def expect_inequality(actual, other)
      expect(actual.eql?(other)).to be_falsey
      expect(actual).not_to eq(other)
    end

    def expect_equality(actual, other)
      expect(actual).to eq(other)
      expect(actual.eql?(other)).to be_truthy
      expect(actual.hash).to eq(other.hash)
    end

    def make_new(name: 'an_event', time_framed: true, filter: { label: 'a_value' })
      described_class.new(name: name, time_framed: time_framed, filter: filter)
    end

    it 'treats objects identical with identical attributes' do
      expect_equality(make_new, make_new)
    end

    it 'different name leads to in-equality' do
      expect_inequality(make_new, make_new(name: 'another_event'))
    end

    it 'different time_framed leads to in-equality' do
      expect_inequality(make_new, make_new(time_framed: false))
    end

    it 'different filter leads to in-equality' do
      expect_inequality(make_new, make_new(filter: {}))
      expect_inequality(make_new, make_new(filter: { label: 'another_value' }))
      expect_inequality(make_new, make_new(filter: { property: 'a_property' }))
    end
  end
end
