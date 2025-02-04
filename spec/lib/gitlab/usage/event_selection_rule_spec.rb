# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::EventSelectionRule, feature_category: :service_ping do
  describe '.initialize' do
    it 'sets the attributes' do
      event_selection_rule = described_class.new(
        name: 'an_event',
        time_framed: true,
        filter: { label: 'a_label' },
        unique_identifier_name: :user
      )

      expect(event_selection_rule.name).to eq('an_event')
      expect(event_selection_rule.time_framed?).to eq(true)
      expect(event_selection_rule.filter).to eq({ label: 'a_label' })
      expect(event_selection_rule.unique_identifier_name).to eq(:user)
    end
  end

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

      context 'with unique identifier' do
        let(:event_selection_rule) do
          described_class.new(
            name: 'example_event',
            time_framed: false,
            filter: filter,
            unique_identifier_name: :user
          )
        end

        it 'returns the correct key with filter' do
          expect(event_selection_rule.redis_key_for_date)
            .to eq('{hll_counters}_example_event-filter:[label:npm,property:deploy_token]-user')

          expect(event_selection_rule.redis_key_for_date).to match(Gitlab::Redis::HLL::KEY_REGEX)
        end
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
      let(:unique_identifier_name) { nil }
      let(:event_selection_rule) do
        described_class.new(
          name: 'an_event',
          time_framed: time_framed,
          filter: { label: 'foo' },
          unique_identifier_name: unique_identifier_name
        )
      end

      context 'when time_frame is "all"' do
        let(:time_framed) { false }

        it 'returns an array with a single redis key' do
          expect(event_selection_rule.redis_keys_for_time_frame('all'))
            .to eq(['{event_counters}_an_event-filter:[label:foo]'])
        end
      end

      context 'when unique_identifier_name is nil' do
        context 'when time_frame is "7d"' do
          it 'returns an array with a single redis keys for the correct week' do
            expect(event_selection_rule.redis_keys_for_time_frame('7d'))
              .to eq(["{event_counters}_an_event-filter:[label:foo]-2024-21"])
          end

          context 'when key is overridden' do
            it 'uses the legacy key' do
              stub_file_read(Gitlab::UsageDataCounters::HLLRedisCounter::KEY_OVERRIDES_PATH,
                content: 'an_event-filter:[label:foo]: a_legacy_key')

              expect(event_selection_rule.redis_keys_for_time_frame('7d'))
               .to eq(["{event_counters}_a_legacy_key-2024-21"])
            end
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

      context 'when unique_identifier_name is set' do
        let(:unique_identifier_name) { :user }

        context 'when time_frame is "7d"' do
          it 'returns an array with a single redis keys for the correct week' do
            expect(event_selection_rule.redis_keys_for_time_frame('7d'))
              .to eq(["{hll_counters}_an_event-filter:[label:foo]-user-2024-21"])
          end
        end

        context 'when time_frame is "28d"' do
          it 'returns an array with a keys for the last 4 full weeks' do
            expect(event_selection_rule.redis_keys_for_time_frame('28d')).to eq(
              [
                "{hll_counters}_an_event-filter:[label:foo]-user-2024-18",
                "{hll_counters}_an_event-filter:[label:foo]-user-2024-19",
                "{hll_counters}_an_event-filter:[label:foo]-user-2024-20",
                "{hll_counters}_an_event-filter:[label:foo]-user-2024-21"
              ]
            )
          end
        end
      end
    end
  end

  describe '#total_counter?' do
    subject do
      described_class
        .new(name: 'an_event', time_framed: true, unique_identifier_name: unique_identifier_name)
        .total_counter?
    end

    context 'when it has unique_identifier_name' do
      let(:unique_identifier_name) { 'user' }

      it { is_expected.to eq false }
    end

    context 'when it has no unique_identifier_name' do
      let(:unique_identifier_name) { nil }

      it { is_expected.to eq true }
    end
  end

  describe '.matches?' do
    subject do
      described_class
        .new(name: 'an_event', time_framed: true, filter: filter, unique_identifier_name: :user)
        .matches?(additional_properties)
    end

    context 'with no filter' do
      let(:filter) { {} }
      let(:additional_properties) { {} }

      context "with no additional_properties" do
        let(:additional_properties) { {} }

        it { is_expected.to eq true }
      end

      context "with additional_properties" do
        let(:additional_properties) { { label: 'label1' } }

        it { is_expected.to eq true }
      end
    end

    context 'with filter' do
      let(:filter) { { label: 'label1' } }

      context "with matching additional_properties" do
        let(:additional_properties) { { label: 'label1', proeprty: 'prop1' } }

        it { is_expected.to eq true }
      end

      context "with not matching additional_properties" do
        let(:additional_properties) { { proeprty: 'prop1' } }

        it { is_expected.to eq false }
      end

      context "with no additional_properties" do
        let(:additional_properties) { {} }

        it { is_expected.to eq false }
      end
    end
  end

  describe 'object equality - #eql' do
    def expect_inequality(actual, other)
      expect(actual.eql?(other)).to be_falsey
      expect(actual).not_to eq(other)
      expect(actual.hash).not_to eq(other.hash)
    end

    def expect_equality(actual, other)
      expect(actual).to eq(other)
      expect(actual.eql?(other)).to be_truthy
      expect(actual.hash).to eq(other.hash)
    end

    def make_new(name: 'an_event', time_framed: true, filter: { label: 'a_value' }, unique_identifier_name: :user)
      described_class.new(
        name: name,
        time_framed: time_framed,
        filter: filter,
        unique_identifier_name: unique_identifier_name
      )
    end

    it 'treats objects identical with identical attributes' do
      expect_equality(make_new, make_new)
    end

    it 'compared to different class leads to in-equality' do
      expect_inequality(make_new, 'a string')
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

    it 'different unique_identifier_name leads to in-equality' do
      expect_inequality(make_new, make_new(unique_identifier_name: nil))
      expect_inequality(make_new, make_new(unique_identifier_name: :namespace))
    end
  end
end
