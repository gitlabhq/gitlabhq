# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::UsageDataCounters::HLLRedisCounter, :clean_gitlab_redis_shared_state do
  let(:entity1) { 'dfb9d2d2-f56c-4c77-8aeb-6cddc4a1f857' }
  let(:entity2) { '1dd9afb2-a3ee-4de1-8ae3-a405579c8584' }
  let(:entity3) { '34rfjuuy-ce56-sa35-ds34-dfer567dfrf2' }
  let(:entity4) { '8b9a2671-2abf-4bec-a682-22f6a8f7bf31' }

  let(:default_context) { 'default' }
  let(:invalid_context) { 'invalid' }

  around do |example|
    # We need to freeze to a reference time
    # because visits are grouped by the week number in the year
    # Without freezing the time, the test may behave inconsistently
    # depending on which day of the week test is run.
    # Monday 6th of June
    described_class.clear_memoization(:known_events)
    reference_time = Time.utc(2020, 6, 1)
    travel_to(reference_time) { example.run }
    described_class.clear_memoization(:known_events)
  end

  describe '.track_event' do
    # ToDo: remove during https://gitlab.com/groups/gitlab-org/-/epics/9542 cleanup
    describe 'daily to weekly key migration precautions' do
      let(:event_name) { 'example_event' }
      let(:known_events) do
        [
          { name: event_name, aggregation: 'daily' }
        ].map(&:with_indifferent_access)
      end

      let(:start_date) { (Date.current - 1.week).beginning_of_week }
      let(:end_date) { Date.current }

      let(:daily_event) { known_events.first }
      let(:daily_key) { described_class.send(:redis_key, daily_event, start_date) }
      let(:weekly_key) do
        weekly_event = known_events.first.merge(aggregation: 'weekly')
        described_class.send(:redis_key, weekly_event, start_date)
      end

      before do
        allow(described_class).to receive(:known_events).and_return(known_events)
      end

      shared_examples 'writes daily events to daily and weekly keys' do
        it :aggregate_failures do
          expect(Gitlab::Redis::HLL).to receive(:add).with(expiry: 29.days, key: daily_key, value: 1).and_call_original
          expect(Gitlab::Redis::HLL).to receive(:add).with(expiry: 6.weeks, key: weekly_key, value: 1).and_call_original

          described_class.track_event(event_name, values: 1, time: start_date)
        end
      end

      context 'when revert_daily_hll_events_to_weekly_aggregation FF is disabled' do
        before do
          stub_feature_flags(revert_daily_hll_events_to_weekly_aggregation: false)
        end

        it_behaves_like 'writes daily events to daily and weekly keys'

        it 'aggregates weekly for daily keys', :aggregate_failures do
          expect(Gitlab::Redis::HLL).to receive(:count).with(keys: [weekly_key]).and_call_original
          expect(Gitlab::Redis::HLL).not_to receive(:count).with(keys: [daily_key]).and_call_original

          described_class.unique_events(event_names: [event_name], start_date: start_date, end_date: end_date)
        end
      end

      context 'when revert_daily_hll_events_to_weekly_aggregation FF is enabled' do
        before do
          stub_feature_flags(revert_daily_hll_events_to_weekly_aggregation: true)
        end

        # we want to write events no matter of the feature state
        it_behaves_like 'writes daily events to daily and weekly keys'

        it 'aggregates daily for daily keys', :aggregate_failures do
          expect(Gitlab::Redis::HLL).to receive(:count).with(keys: [daily_key]).and_call_original
          expect(Gitlab::Redis::HLL).not_to receive(:count).with(keys: [weekly_key]).and_call_original

          described_class.unique_events(event_names: [event_name], start_date: start_date, end_date: start_date)
        end
      end
    end
  end

  describe '.known_events' do
    let(:ce_temp_dir) { Dir.mktmpdir }
    let(:ce_temp_file) { Tempfile.new(%w[common .yml], ce_temp_dir) }
    let(:ce_event) do
      {
        "name" => "ce_event",
        "aggregation" => "weekly"
      }
    end

    before do
      stub_const("#{described_class}::KNOWN_EVENTS_PATH", File.expand_path('*.yml', ce_temp_dir))
      File.open(ce_temp_file.path, "w+b") { |f| f.write [ce_event].to_yaml }
    end

    after do
      ce_temp_file.unlink
      FileUtils.remove_entry(ce_temp_dir) if Dir.exist?(ce_temp_dir)
    end

    it 'returns ce events' do
      expect(described_class.known_events).to include(ce_event)
    end
  end

  describe 'known_events' do
    let(:weekly_event) { 'g_analytics_contribution' }
    let(:daily_event) { 'g_analytics_search' }
    let(:analytics_slot_event) { 'g_analytics_contribution' }
    let(:compliance_slot_event) { 'g_compliance_dashboard' }
    let(:category_analytics_event) { 'g_analytics_search' }
    let(:category_productivity_event) { 'g_analytics_productivity' }
    let(:no_slot) { 'no_slot' }
    let(:different_aggregation) { 'different_aggregation' }
    let(:custom_daily_event) { 'g_analytics_custom' }
    let(:context_event) { 'context_event' }

    let(:global_category) { 'global' }
    let(:compliance_category) { 'compliance' }
    let(:productivity_category) { 'productivity' }
    let(:analytics_category) { 'analytics' }
    let(:other_category) { 'other' }

    let(:known_events) do
      [
        { name: weekly_event, aggregation: "weekly" },
        { name: daily_event, aggregation: "daily" },
        { name: category_productivity_event, aggregation: "weekly" },
        { name: compliance_slot_event,  aggregation: "weekly" },
        { name: no_slot, aggregation: "daily" },
        { name: different_aggregation, aggregation: "monthly" },
        { name: context_event, aggregation: 'weekly' }
      ].map(&:with_indifferent_access)
    end

    before do
      skip_feature_flags_yaml_validation
      skip_default_enabled_yaml_check
      allow(described_class).to receive(:known_events).and_return(known_events)
    end

    describe '.track_event' do
      context 'with redis_hll_tracking' do
        it 'tracks the event when feature enabled' do
          stub_feature_flags(redis_hll_tracking: true)

          expect(Gitlab::Redis::HLL).to receive(:add)

          described_class.track_event(weekly_event, values: 1)
        end

        it 'does not track the event with feature flag disabled' do
          stub_feature_flags(redis_hll_tracking: false)

          expect(Gitlab::Redis::HLL).not_to receive(:add)

          described_class.track_event(weekly_event, values: 1)
        end
      end

      context 'when usage_ping is disabled' do
        it 'does not track the event' do
          allow(::ServicePing::ServicePingSettings).to receive(:enabled?).and_return(false)

          described_class.track_event(weekly_event, values: entity1, time: Date.current)

          expect(Gitlab::Redis::HLL).not_to receive(:add)
        end
      end

      context 'when usage_ping is enabled' do
        before do
          allow(::ServicePing::ServicePingSettings).to receive(:enabled?).and_return(true)
        end

        it 'tracks event when using symbol' do
          expect(Gitlab::Redis::HLL).to receive(:add)

          described_class.track_event(:g_analytics_contribution, values: entity1)
        end

        it 'tracks events with multiple values' do
          values = [entity1, entity2]
          expect(Gitlab::Redis::HLL).to receive(:add).with(key: /g_analytics_contribution/, value: values,
            expiry: described_class::DEFAULT_WEEKLY_KEY_EXPIRY_LENGTH)

          described_class.track_event(:g_analytics_contribution, values: values)
        end

        it "raise error if metrics don't have same aggregation" do
          expect { described_class.track_event(different_aggregation, values: entity1, time: Date.current) }.to raise_error(Gitlab::UsageDataCounters::HLLRedisCounter::UnknownAggregation)
        end

        it 'raise error if metrics of unknown event' do
          expect { described_class.track_event('unknown', values: entity1, time: Date.current) }.to raise_error(Gitlab::UsageDataCounters::HLLRedisCounter::UnknownEvent)
        end

        context 'when Rails environment is production' do
          before do
            allow(Rails.env).to receive(:development?).and_return(false)
            allow(Rails.env).to receive(:test?).and_return(false)
          end

          it 'reports only UnknownEvent exception' do
            expect(Gitlab::ErrorTracking).to receive(:track_and_raise_for_dev_exception)
                                               .with(Gitlab::UsageDataCounters::HLLRedisCounter::UnknownEvent)
                                               .once
                                               .and_call_original

            expect { described_class.track_event('unknown', values: entity1, time: Date.current) }.not_to raise_error
          end
        end

        it 'reports an error if Feature.enabled raise an error' do
          expect(Feature).to receive(:enabled?).and_raise(StandardError.new)
          expect(Gitlab::ErrorTracking).to receive(:track_and_raise_for_dev_exception)

          described_class.track_event(:g_analytics_contribution, values: entity1, time: Date.current)
        end

        context 'for weekly events' do
          it 'sets the keys in Redis to expire' do
            described_class.track_event("g_compliance_dashboard", values: entity1)

            Gitlab::Redis::SharedState.with do |redis|
              keys = redis.scan_each(match: "{#{described_class::REDIS_SLOT}}_g_compliance_dashboard-*").to_a
              expect(keys).not_to be_empty

              keys.each do |key|
                expect(redis.ttl(key)).to be_within(5.seconds).of(described_class::DEFAULT_WEEKLY_KEY_EXPIRY_LENGTH)
              end
            end
          end
        end

        context 'for daily events' do
          it 'sets the keys in Redis to expire' do
            described_class.track_event("no_slot", values: entity1)

            Gitlab::Redis::SharedState.with do |redis|
              keys = redis.scan_each(match: "*_no_slot").to_a
              expect(keys).not_to be_empty

              keys.each do |key|
                expect(redis.ttl(key)).to be_within(5.seconds).of(described_class::DEFAULT_DAILY_KEY_EXPIRY_LENGTH)
              end
            end
          end
        end
      end
    end

    describe '.track_event_in_context' do
      context 'with valid contex' do
        it 'increments context event counter' do
          expect(Gitlab::Redis::HLL).to receive(:add) do |kwargs|
            expect(kwargs[:key]).to match(/^#{default_context}_.*/)
          end

          described_class.track_event_in_context(context_event, values: entity1, context: default_context)
        end

        it 'tracks events with multiple values' do
          values = [entity1, entity2]
          expect(Gitlab::Redis::HLL).to receive(:add).with(key: /g_analytics_contribution/,
            value: values,
            expiry: described_class::DEFAULT_WEEKLY_KEY_EXPIRY_LENGTH)

          described_class.track_event_in_context(:g_analytics_contribution, values: values, context: default_context)
        end
      end

      context 'with empty context' do
        it 'does not increment a counter' do
          expect(Gitlab::Redis::HLL).not_to receive(:add)

          described_class.track_event_in_context(context_event, values: entity1, context: '')
        end
      end

      context 'when sending invalid context' do
        it 'does not increment a counter' do
          expect(Gitlab::Redis::HLL).not_to receive(:add)

          described_class.track_event_in_context(context_event, values: entity1, context: invalid_context)
        end
      end
    end

    describe '.unique_events' do
      before do
        # events in current week, should not be counted as week is not complete
        described_class.track_event(weekly_event, values: entity1, time: Date.current)
        described_class.track_event(weekly_event, values: entity2, time: Date.current)

        # Events last week
        described_class.track_event(weekly_event, values: entity1, time: 2.days.ago)
        described_class.track_event(weekly_event, values: entity1, time: 2.days.ago)
        described_class.track_event(no_slot, values: entity1, time: 2.days.ago)

        # Events 2 weeks ago
        described_class.track_event(weekly_event, values: entity1, time: 2.weeks.ago)

        # Events 4 weeks ago
        described_class.track_event(weekly_event, values: entity3, time: 4.weeks.ago)
        described_class.track_event(weekly_event, values: entity4, time: 29.days.ago)

        # events in current day should be counted in daily aggregation
        described_class.track_event(daily_event, values: entity1, time: Date.current)
        described_class.track_event(daily_event, values: entity2, time: Date.current)

        # Events last week
        described_class.track_event(daily_event, values: entity1, time: 2.days.ago)
        described_class.track_event(daily_event, values: entity1, time: 2.days.ago)

        # Events 2 weeks ago
        described_class.track_event(daily_event, values: entity1, time: 14.days.ago)

        # Events 4 weeks ago
        described_class.track_event(daily_event, values: entity3, time: 28.days.ago)
        described_class.track_event(daily_event, values: entity4, time: 29.days.ago)
      end

      it 'returns 0 if there are no keys for the given events' do
        expect(Gitlab::Redis::HLL).not_to receive(:count)
        expect(described_class.unique_events(event_names: [weekly_event], start_date: Date.current, end_date: 4.weeks.ago)).to eq(-1)
      end

      it "raise error if metrics don't have same aggregation" do
        expect do
          described_class.unique_events(event_names: [daily_event, weekly_event], start_date: 4.weeks.ago, end_date: Date.current)
        end.to raise_error(Gitlab::UsageDataCounters::HLLRedisCounter::AggregationMismatch)
      end

      context 'when data for the last complete week' do
        it { expect(described_class.unique_events(event_names: [weekly_event], start_date: 1.week.ago, end_date: Date.current)).to eq(1) }
      end

      context 'when data for the last 4 complete weeks' do
        it { expect(described_class.unique_events(event_names: [weekly_event], start_date: 4.weeks.ago, end_date: Date.current)).to eq(2) }
      end

      context 'when data for the week 4 weeks ago' do
        it { expect(described_class.unique_events(event_names: [weekly_event], start_date: 4.weeks.ago, end_date: 3.weeks.ago)).to eq(1) }
      end

      context 'when using symbol as parameter' do
        it { expect(described_class.unique_events(event_names: [weekly_event.to_sym], start_date: 4.weeks.ago, end_date: 3.weeks.ago)).to eq(1) }
      end

      context 'when using daily aggregation' do
        it { expect(described_class.unique_events(event_names: [daily_event], start_date: 7.days.ago, end_date: Date.current)).to eq(2) }
        it { expect(described_class.unique_events(event_names: [daily_event], start_date: 28.days.ago, end_date: Date.current)).to eq(3) }
        it { expect(described_class.unique_events(event_names: [daily_event], start_date: 28.days.ago, end_date: 21.days.ago)).to eq(1) }
      end

      context 'when no slot is set' do
        it { expect(described_class.unique_events(event_names: [no_slot], start_date: 7.days.ago, end_date: Date.current)).to eq(1) }
      end

      context 'when data crosses into new year' do
        it 'does not raise error' do
          expect { described_class.unique_events(event_names: [weekly_event], start_date: DateTime.parse('2020-12-26'), end_date: DateTime.parse('2021-02-01')) }
            .not_to raise_error
        end
      end
    end
  end

  describe '.weekly_redis_keys' do
    using RSpec::Parameterized::TableSyntax

    let(:weekly_event) { 'i_search_total' }
    let(:redis_event) { described_class.send(:event_for, weekly_event) }
    let(:week_one) { "{#{described_class::REDIS_SLOT}}_i_search_total-2020-52" }
    let(:week_two) { "{#{described_class::REDIS_SLOT}}_i_search_total-2020-53" }
    let(:week_three) { "{#{described_class::REDIS_SLOT}}_i_search_total-2021-01" }
    let(:week_four) { "{#{described_class::REDIS_SLOT}}_i_search_total-2021-02" }

    subject(:weekly_redis_keys) { described_class.send(:weekly_redis_keys, events: [redis_event], start_date: DateTime.parse(start_date), end_date: DateTime.parse(end_date)) }

    where(:start_date, :end_date, :keys) do
      '2020-12-21' | '2020-12-21' | []
      '2020-12-21' | '2020-12-20' | []
      '2020-12-21' | '2020-11-21' | []
      '2021-01-01' | '2020-12-28' | []
      '2020-12-21' | '2020-12-28' | lazy { [week_one] }
      '2020-12-21' | '2021-01-01' | lazy { [week_one] }
      '2020-12-27' | '2021-01-01' | lazy { [week_one] }
      '2020-12-26' | '2021-01-04' | lazy { [week_one, week_two] }
      '2020-12-26' | '2021-01-11' | lazy { [week_one, week_two, week_three] }
      '2020-12-26' | '2021-01-17' | lazy { [week_one, week_two, week_three] }
      '2020-12-26' | '2021-01-18' | lazy { [week_one, week_two, week_three, week_four] }
    end

    with_them do
      it "returns the correct keys" do
        expect(subject).to match(keys)
      end
    end

    it 'returns 1 key for last for week' do
      expect(described_class.send(:weekly_redis_keys, events: [redis_event], start_date: 7.days.ago.to_date, end_date: Date.current).size).to eq 1
    end

    it 'returns 4 key for last for weeks' do
      expect(described_class.send(:weekly_redis_keys, events: [redis_event], start_date: 4.weeks.ago.to_date, end_date: Date.current).size).to eq 4
    end
  end

  describe 'context level tracking' do
    using RSpec::Parameterized::TableSyntax

    let(:known_events) do
      [
        { name: 'event_name_1', aggregation: "weekly" },
        { name: 'event_name_2', aggregation: "weekly" },
        { name: 'event_name_3', aggregation: "weekly" }
      ].map(&:with_indifferent_access)
    end

    before do
      allow(described_class).to receive(:known_events).and_return(known_events)
      allow(described_class).to receive(:categories).and_return(%w(category1 category2))

      described_class.track_event_in_context('event_name_1', values: [entity1, entity3], context: default_context, time: 2.days.ago)
      described_class.track_event_in_context('event_name_1', values: entity3, context: default_context, time: 2.days.ago)
      described_class.track_event_in_context('event_name_1', values: entity3, context: invalid_context, time: 2.days.ago)
      described_class.track_event_in_context('event_name_2', values: [entity1, entity2], context: '', time: 2.weeks.ago)
    end

    subject(:unique_events) { described_class.unique_events(event_names: event_names, start_date: 4.weeks.ago, end_date: Date.current, context: context) }

    context 'with correct arguments' do
      where(:event_names, :context, :value) do
        ['event_name_1'] | 'default' | 2
        ['event_name_1'] | ''        | 0
        ['event_name_2'] | ''        | 0
      end

      with_them do
        it { is_expected.to eq value }
      end
    end

    context 'with invalid context' do
      it 'raise error' do
        expect { described_class.unique_events(event_names: 'event_name_1', start_date: 4.weeks.ago, end_date: Date.current, context: invalid_context) }.to raise_error(Gitlab::UsageDataCounters::HLLRedisCounter::InvalidContext)
      end
    end
  end

  describe '.calculate_events_union' do
    let(:time_range) { { start_date: 7.days.ago, end_date: DateTime.current } }
    let(:known_events) do
      [
        { name: 'event1_slot', aggregation: "weekly" },
        { name: 'event2_slot', aggregation: "weekly" },
        { name: 'event3_slot', aggregation: "weekly" },
        { name: 'event5_slot', aggregation: "daily" },
        { name: 'event4', aggregation: "weekly" }
      ].map(&:with_indifferent_access)
    end

    before do
      allow(described_class).to receive(:known_events).and_return(known_events)

      described_class.track_event('event1_slot', values: entity1, time: 2.days.ago)
      described_class.track_event('event1_slot', values: entity2, time: 2.days.ago)
      described_class.track_event('event1_slot', values: entity3, time: 2.days.ago)
      described_class.track_event('event2_slot', values: entity1, time: 2.days.ago)
      described_class.track_event('event2_slot', values: entity2, time: 3.days.ago)
      described_class.track_event('event2_slot', values: entity3, time: 3.days.ago)
      described_class.track_event('event3_slot', values: entity1, time: 3.days.ago)
      described_class.track_event('event3_slot', values: entity2, time: 3.days.ago)
      described_class.track_event('event5_slot', values: entity2, time: 3.days.ago)

      # events out of time scope
      described_class.track_event('event2_slot', values: entity4, time: 8.days.ago)

      # events in different slots
      described_class.track_event('event4', values: entity1, time: 2.days.ago)
      described_class.track_event('event4', values: entity2, time: 2.days.ago)
    end

    it 'calculates union of given events', :aggregate_failures do
      expect(described_class.calculate_events_union(**time_range.merge(event_names: %w[event4]))).to eq 2
      expect(described_class.calculate_events_union(**time_range.merge(event_names: %w[event1_slot event2_slot event3_slot]))).to eq 3
    end

    it 'returns 0 if there are no keys for given events' do
      expect(Gitlab::Redis::HLL).not_to receive(:count)
      expect(described_class.calculate_events_union(event_names: %w[event1_slot event2_slot event3_slot], start_date: Date.current, end_date: 4.weeks.ago)).to eq(-1)
    end
  end

  describe '.weekly_time_range' do
    it 'return hash with weekly time range boundaries' do
      expect(described_class.weekly_time_range).to eq(start_date: 7.days.ago.to_date, end_date: Date.current)
    end
  end

  describe '.monthly_time_range' do
    it 'return hash with monthly time range boundaries' do
      expect(described_class.monthly_time_range).to eq(start_date: 4.weeks.ago.to_date, end_date: Date.current)
    end
  end
end
