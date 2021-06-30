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
    reference_time = Time.utc(2020, 6, 1)
    travel_to(reference_time) { example.run }
  end

  describe '.categories' do
    it 'gets all unique category names' do
      expect(described_class.categories).to contain_exactly(
        'deploy_token_packages',
        'user_packages',
        'compliance',
        'ecosystem',
        'analytics',
        'ide_edit',
        'search',
        'source_code',
        'incident_management',
        'incident_management_alerts',
        'incident_management_oncall',
        'testing',
        'issues_edit',
        'ci_secrets_management',
        'snippets',
        'code_review',
        'terraform',
        'ci_templates',
        'quickactions',
        'pipeline_authoring',
        'epics_usage',
        'epic_boards_usage',
        'secure',
        'network_policies'
      )
    end
  end

  describe 'known_events' do
    let(:feature) { 'test_hll_redis_counter_ff_check' }

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
        { name: weekly_event, redis_slot: "analytics", category: analytics_category, expiry: 84, aggregation: "weekly", feature_flag: feature },
        { name: daily_event, redis_slot: "analytics", category: analytics_category, expiry: 84, aggregation: "daily" },
        { name: category_productivity_event, redis_slot: "analytics", category: productivity_category, aggregation: "weekly" },
        { name: compliance_slot_event, redis_slot: "compliance", category: compliance_category, aggregation: "weekly" },
        { name: no_slot, category: global_category, aggregation: "daily" },
        { name: different_aggregation, category: global_category, aggregation: "monthly" },
        { name: context_event, category: other_category, expiry: 6, aggregation: 'weekly' }
      ].map(&:with_indifferent_access)
    end

    before do
      skip_feature_flags_yaml_validation
      skip_default_enabled_yaml_check
      allow(described_class).to receive(:known_events).and_return(known_events)
    end

    describe '.events_for_category' do
      it 'gets the event names for given category' do
        expect(described_class.events_for_category(:analytics)).to contain_exactly(weekly_event, daily_event)
      end
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

      context 'with event feature flag set' do
        it 'tracks the event when feature enabled' do
          stub_feature_flags(feature => true)

          expect(Gitlab::Redis::HLL).to receive(:add)

          described_class.track_event(weekly_event, values: 1)
        end

        it 'does not track the event with feature flag disabled' do
          stub_feature_flags(feature => false)

          expect(Gitlab::Redis::HLL).not_to receive(:add)

          described_class.track_event(weekly_event, values: 1)
        end
      end

      context 'with no event feature flag set' do
        it 'tracks the event' do
          expect(Gitlab::Redis::HLL).to receive(:add)

          described_class.track_event(daily_event, values: 1)
        end
      end

      context 'when usage_ping is disabled' do
        it 'does not track the event' do
          stub_application_setting(usage_ping_enabled: false)

          described_class.track_event(weekly_event, values: entity1, time: Date.current)

          expect(Gitlab::Redis::HLL).not_to receive(:add)
        end
      end

      context 'when usage_ping is enabled' do
        before do
          stub_application_setting(usage_ping_enabled: true)
        end

        it 'tracks event when using symbol' do
          expect(Gitlab::Redis::HLL).to receive(:add)

          described_class.track_event(:g_analytics_contribution, values: entity1)
        end

        it 'tracks events with multiple values' do
          values = [entity1, entity2]
          expect(Gitlab::Redis::HLL).to receive(:add).with(key: /g_{analytics}_contribution/, value: values, expiry: 84.days)

          described_class.track_event(:g_analytics_contribution, values: values)
        end

        it "raise error if metrics don't have same aggregation" do
          expect { described_class.track_event(different_aggregation, values: entity1, time: Date.current) }.to raise_error(Gitlab::UsageDataCounters::HLLRedisCounter::UnknownAggregation)
        end

        it 'raise error if metrics of unknown event' do
          expect { described_class.track_event('unknown', values: entity1, time: Date.current) }.to raise_error(Gitlab::UsageDataCounters::HLLRedisCounter::UnknownEvent)
        end

        it 'reports an error if Feature.enabled raise an error' do
          expect(Feature).to receive(:enabled?).and_raise(StandardError.new)
          expect(Gitlab::ErrorTracking).to receive(:track_and_raise_for_dev_exception)

          described_class.track_event(:g_analytics_contribution, values: entity1, time: Date.current)
        end

        context 'for weekly events' do
          it 'sets the keys in Redis to expire automatically after the given expiry time' do
            described_class.track_event("g_analytics_contribution", values: entity1)

            Gitlab::Redis::SharedState.with do |redis|
              keys = redis.scan_each(match: "g_{analytics}_contribution-*").to_a
              expect(keys).not_to be_empty

              keys.each do |key|
                expect(redis.ttl(key)).to be_within(5.seconds).of(12.weeks)
              end
            end
          end

          it 'sets the keys in Redis to expire automatically after 6 weeks by default' do
            described_class.track_event("g_compliance_dashboard", values: entity1)

            Gitlab::Redis::SharedState.with do |redis|
              keys = redis.scan_each(match: "g_{compliance}_dashboard-*").to_a
              expect(keys).not_to be_empty

              keys.each do |key|
                expect(redis.ttl(key)).to be_within(5.seconds).of(6.weeks)
              end
            end
          end
        end

        context 'for daily events' do
          it 'sets the keys in Redis to expire after the given expiry time' do
            described_class.track_event("g_analytics_search", values: entity1)

            Gitlab::Redis::SharedState.with do |redis|
              keys = redis.scan_each(match: "*-g_{analytics}_search").to_a
              expect(keys).not_to be_empty

              keys.each do |key|
                expect(redis.ttl(key)).to be_within(5.seconds).of(84.days)
              end
            end
          end

          it 'sets the keys in Redis to expire after 29 days by default' do
            described_class.track_event("no_slot", values: entity1)

            Gitlab::Redis::SharedState.with do |redis|
              keys = redis.scan_each(match: "*-{no_slot}").to_a
              expect(keys).not_to be_empty

              keys.each do |key|
                expect(redis.ttl(key)).to be_within(5.seconds).of(29.days)
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
            expect(kwargs[:key]).to match(/^#{default_context}\_.*/)
          end

          described_class.track_event_in_context(context_event, values: entity1, context: default_context)
        end

        it 'tracks events with multiple values' do
          values = [entity1, entity2]
          expect(Gitlab::Redis::HLL).to receive(:add).with(key: /g_{analytics}_contribution/, value: values, expiry: 84.days)

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

      it 'raise error if metrics are not in the same slot' do
        expect do
          described_class.unique_events(event_names: [compliance_slot_event, analytics_slot_event], start_date: 4.weeks.ago, end_date: Date.current)
        end.to raise_error(Gitlab::UsageDataCounters::HLLRedisCounter::SlotMismatch)
      end

      it 'raise error if metrics are not in the same category' do
        expect do
          described_class.unique_events(event_names: [category_analytics_event, category_productivity_event], start_date: 4.weeks.ago, end_date: Date.current)
        end.to raise_error(Gitlab::UsageDataCounters::HLLRedisCounter::CategoryMismatch)
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

    let(:weekly_event) { 'g_compliance_dashboard' }
    let(:redis_event) { described_class.send(:event_for, weekly_event) }

    subject(:weekly_redis_keys) { described_class.send(:weekly_redis_keys, events: [redis_event], start_date: DateTime.parse(start_date), end_date: DateTime.parse(end_date)) }

    where(:start_date, :end_date, :keys) do
      '2020-12-21' | '2020-12-21' | []
      '2020-12-21' | '2020-12-20' | []
      '2020-12-21' | '2020-11-21' | []
      '2021-01-01' | '2020-12-28' | []
      '2020-12-21' | '2020-12-28' | ['g_{compliance}_dashboard-2020-52']
      '2020-12-21' | '2021-01-01' | ['g_{compliance}_dashboard-2020-52']
      '2020-12-27' | '2021-01-01' | ['g_{compliance}_dashboard-2020-52']
      '2020-12-26' | '2021-01-04' | ['g_{compliance}_dashboard-2020-52', 'g_{compliance}_dashboard-2020-53']
      '2020-12-26' | '2021-01-11' | ['g_{compliance}_dashboard-2020-52', 'g_{compliance}_dashboard-2020-53', 'g_{compliance}_dashboard-2021-01']
      '2020-12-26' | '2021-01-17' | ['g_{compliance}_dashboard-2020-52', 'g_{compliance}_dashboard-2020-53', 'g_{compliance}_dashboard-2021-01']
      '2020-12-26' | '2021-01-18' | ['g_{compliance}_dashboard-2020-52', 'g_{compliance}_dashboard-2020-53', 'g_{compliance}_dashboard-2021-01', 'g_{compliance}_dashboard-2021-02']
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
        { name: 'event_name_1', redis_slot: 'event', category: 'category1', aggregation: "weekly" },
        { name: 'event_name_2', redis_slot: 'event', category: 'category1', aggregation: "weekly" },
        { name: 'event_name_3', redis_slot: 'event', category: 'category1', aggregation: "weekly" }
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

  describe 'unique_events_data' do
    let(:known_events) do
      [
        { name: 'event1_slot', redis_slot: "slot", category: 'category1', aggregation: "weekly" },
        { name: 'event2_slot', redis_slot: "slot", category: 'category1', aggregation: "weekly" },
        { name: 'event3', category: 'category2', aggregation: "weekly" },
        { name: 'event4', category: 'category2', aggregation: "weekly" }
      ].map(&:with_indifferent_access)
    end

    before do
      allow(described_class).to receive(:known_events).and_return(known_events)
      allow(described_class).to receive(:categories).and_return(%w(category1 category2))

      described_class.track_event('event1_slot', values: entity1, time: 2.days.ago)
      described_class.track_event('event2_slot', values: entity2, time: 2.days.ago)
      described_class.track_event('event2_slot', values: entity3, time: 2.weeks.ago)

      # events in different slots
      described_class.track_event('event3', values: entity2, time: 2.days.ago)
      described_class.track_event('event4', values: entity2, time: 2.days.ago)
    end

    it 'returns the number of unique events for all known events' do
      results = {
        "category1" => {
          "event1_slot_weekly" => 1,
          "event1_slot_monthly" => 1,
          "event2_slot_weekly" => 1,
          "event2_slot_monthly" => 2,
          "category1_total_unique_counts_weekly" => 2,
          "category1_total_unique_counts_monthly" => 3
        },
        "category2" => {
          "event3_weekly" => 1,
          "event3_monthly" => 1,
          "event4_weekly" => 1,
          "event4_monthly" => 1
        }
      }

      expect(subject.unique_events_data).to eq(results)
    end
  end

  describe '.calculate_events_union' do
    let(:time_range) { { start_date: 7.days.ago, end_date: DateTime.current } }
    let(:known_events) do
      [
        { name: 'event1_slot', redis_slot: "slot", category: 'category1', aggregation: "weekly" },
        { name: 'event2_slot', redis_slot: "slot", category: 'category2', aggregation: "weekly" },
        { name: 'event3_slot', redis_slot: "slot", category: 'category3', aggregation: "weekly" },
        { name: 'event5_slot', redis_slot: "slot", category: 'category4', aggregation: "daily" },
        { name: 'event4', category: 'category2', aggregation: "weekly" }
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

    it 'calculates union of given events', :aggregate_failure do
      expect(described_class.calculate_events_union(**time_range.merge(event_names: %w[event4]))).to eq 2
      expect(described_class.calculate_events_union(**time_range.merge(event_names: %w[event1_slot event2_slot event3_slot]))).to eq 3
    end

    it 'validates and raise exception if events has mismatched slot or aggregation', :aggregate_failure do
      expect { described_class.calculate_events_union(**time_range.merge(event_names: %w[event1_slot event4])) }.to raise_error described_class::SlotMismatch
      expect { described_class.calculate_events_union(**time_range.merge(event_names: %w[event5_slot event3_slot])) }.to raise_error described_class::AggregationMismatch
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
