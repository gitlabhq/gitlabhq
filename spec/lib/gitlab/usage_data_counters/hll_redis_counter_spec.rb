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
        'compliance',
        'analytics',
        'ide_edit',
        'search',
        'source_code',
        'incident_management',
        'incident_management_alerts',
        'testing',
        'issues_edit',
        'ci_secrets_management',
        'maven_packages',
        'npm_packages',
        'conan_packages',
        'nuget_packages',
        'pypi_packages',
        'composer_packages',
        'generic_packages',
        'golang_packages',
        'debian_packages',
        'container_packages',
        'tag_packages',
        'snippets'
      )
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
        { name: weekly_event, redis_slot: "analytics", category: analytics_category, expiry: 84, aggregation: "weekly" },
        { name: daily_event, redis_slot: "analytics", category: analytics_category, expiry: 84, aggregation: "daily" },
        { name: category_productivity_event, redis_slot: "analytics", category: productivity_category, aggregation: "weekly" },
        { name: compliance_slot_event, redis_slot: "compliance", category: compliance_category, aggregation: "weekly" },
        { name: no_slot, category: global_category, aggregation: "daily" },
        { name: different_aggregation, category: global_category, aggregation: "monthly" },
        { name: context_event, category: other_category, expiry: 6, aggregation: 'weekly' }
      ].map(&:with_indifferent_access)
    end

    before do
      allow(described_class).to receive(:known_events).and_return(known_events)
    end

    describe '.events_for_category' do
      it 'gets the event names for given category' do
        expect(described_class.events_for_category(:analytics)).to contain_exactly(weekly_event, daily_event)
      end
    end

    describe '.track_event' do
      context 'when usage_ping is disabled' do
        it 'does not track the event' do
          stub_application_setting(usage_ping_enabled: false)

          described_class.track_event(entity1, weekly_event, Date.current)

          expect(Gitlab::Redis::HLL).not_to receive(:add)
        end
      end

      context 'when usage_ping is enabled' do
        before do
          stub_application_setting(usage_ping_enabled: true)
        end

        it 'tracks event when using symbol' do
          expect(Gitlab::Redis::HLL).to receive(:add)

          described_class.track_event(entity1, :g_analytics_contribution)
        end

        it "raise error if metrics don't have same aggregation" do
          expect { described_class.track_event(entity1, different_aggregation, Date.current) }.to raise_error(Gitlab::UsageDataCounters::HLLRedisCounter::UnknownAggregation)
        end

        it 'raise error if metrics of unknown aggregation' do
          expect { described_class.track_event(entity1, 'unknown', Date.current) }.to raise_error(Gitlab::UsageDataCounters::HLLRedisCounter::UnknownEvent)
        end

        context 'for weekly events' do
          it 'sets the keys in Redis to expire automatically after the given expiry time' do
            described_class.track_event(entity1, "g_analytics_contribution")

            Gitlab::Redis::SharedState.with do |redis|
              keys = redis.scan_each(match: "g_{analytics}_contribution-*").to_a
              expect(keys).not_to be_empty

              keys.each do |key|
                expect(redis.ttl(key)).to be_within(5.seconds).of(12.weeks)
              end
            end
          end

          it 'sets the keys in Redis to expire automatically after 6 weeks by default' do
            described_class.track_event(entity1, "g_compliance_dashboard")

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
            described_class.track_event(entity1, "g_analytics_search")

            Gitlab::Redis::SharedState.with do |redis|
              keys = redis.scan_each(match: "*-g_{analytics}_search").to_a
              expect(keys).not_to be_empty

              keys.each do |key|
                expect(redis.ttl(key)).to be_within(5.seconds).of(84.days)
              end
            end
          end

          it 'sets the keys in Redis to expire after 29 days by default' do
            described_class.track_event(entity1, "no_slot")

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
        it 'increments conext event counte' do
          expect(Gitlab::Redis::HLL).to receive(:add) do |kwargs|
            expect(kwargs[:key]).to match(/^#{default_context}\_.*/)
          end

          described_class.track_event_in_context(entity1, context_event, default_context)
        end
      end

      context 'with empty context' do
        it 'does not increment a counter' do
          expect(Gitlab::Redis::HLL).not_to receive(:add)

          described_class.track_event_in_context(entity1, context_event, '')
        end
      end

      context 'when sending invalid context' do
        it 'does not increment a counter' do
          expect(Gitlab::Redis::HLL).not_to receive(:add)

          described_class.track_event_in_context(entity1, context_event, invalid_context)
        end
      end
    end

    describe '.unique_events' do
      before do
        # events in current week, should not be counted as week is not complete
        described_class.track_event(entity1, weekly_event, Date.current)
        described_class.track_event(entity2, weekly_event, Date.current)

        # Events last week
        described_class.track_event(entity1, weekly_event, 2.days.ago)
        described_class.track_event(entity1, weekly_event, 2.days.ago)
        described_class.track_event(entity1, no_slot, 2.days.ago)

        # Events 2 weeks ago
        described_class.track_event(entity1, weekly_event, 2.weeks.ago)

        # Events 4 weeks ago
        described_class.track_event(entity3, weekly_event, 4.weeks.ago)
        described_class.track_event(entity4, weekly_event, 29.days.ago)

        # events in current day should be counted in daily aggregation
        described_class.track_event(entity1, daily_event, Date.current)
        described_class.track_event(entity2, daily_event, Date.current)

        # Events last week
        described_class.track_event(entity1, daily_event, 2.days.ago)
        described_class.track_event(entity1, daily_event, 2.days.ago)

        # Events 2 weeks ago
        described_class.track_event(entity1, daily_event, 14.days.ago)

        # Events 4 weeks ago
        described_class.track_event(entity3, daily_event, 28.days.ago)
        described_class.track_event(entity4, daily_event, 29.days.ago)
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

      described_class.track_event_in_context([entity1, entity3], 'event_name_1', default_context, 2.days.ago)
      described_class.track_event_in_context(entity3, 'event_name_1', default_context, 2.days.ago)
      described_class.track_event_in_context(entity3, 'event_name_1', invalid_context, 2.days.ago)
      described_class.track_event_in_context([entity1, entity2], 'event_name_2', '', 2.weeks.ago)
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

      described_class.track_event(entity1, 'event1_slot', 2.days.ago)
      described_class.track_event(entity2, 'event2_slot', 2.days.ago)
      described_class.track_event(entity3, 'event2_slot', 2.weeks.ago)

      # events in different slots
      described_class.track_event(entity2, 'event3', 2.days.ago)
      described_class.track_event(entity2, 'event4', 2.days.ago)
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

  context 'aggregated_metrics_data' do
    let(:known_events) do
      [
        { name: 'event1_slot', redis_slot: "slot", category: 'category1', aggregation: "weekly" },
        { name: 'event2_slot', redis_slot: "slot", category: 'category2', aggregation: "weekly" },
        { name: 'event3_slot', redis_slot: "slot", category: 'category3', aggregation: "weekly" },
        { name: 'event5_slot', redis_slot: "slot", category: 'category4', aggregation: "weekly" },
        { name: 'event4', category: 'category2', aggregation: "weekly" }
      ].map(&:with_indifferent_access)
    end

    before do
      allow(described_class).to receive(:known_events).and_return(known_events)
    end

    shared_examples 'aggregated_metrics_data' do
      context 'no aggregated metrics is defined' do
        it 'returns empty hash' do
          allow(described_class).to receive(:aggregated_metrics).and_return([])

          expect(aggregated_metrics_data).to eq({})
        end
      end

      context 'there are aggregated metrics defined' do
        before do
          allow(described_class).to receive(:aggregated_metrics).and_return(aggregated_metrics)
        end

        context 'with AND operator' do
          let(:aggregated_metrics) do
            [
              { name: 'gmau_1', events: %w[event1_slot event2_slot], operator: "AND" },
              { name: 'gmau_2', events: %w[event1_slot event2_slot event3_slot], operator: "AND" },
              { name: 'gmau_3', events: %w[event1_slot event2_slot event3_slot event5_slot], operator: "AND" },
              { name: 'gmau_4', events: %w[event4], operator: "AND" }
            ].map(&:with_indifferent_access)
          end

          it 'returns the number of unique events for all known events' do
            results = {
              'gmau_1' => 3,
              'gmau_2' => 2,
              'gmau_3' => 1,
              'gmau_4' => 3
            }

            expect(aggregated_metrics_data).to eq(results)
          end
        end

        context 'with OR operator' do
          let(:aggregated_metrics) do
            [
              { name: 'gmau_1', events: %w[event3_slot event5_slot], operator: "OR" },
              { name: 'gmau_2', events: %w[event1_slot event2_slot event3_slot event5_slot], operator: "OR" },
              { name: 'gmau_3', events: %w[event4], operator: "OR" }
            ].map(&:with_indifferent_access)
          end

          it 'returns the number of unique events for all known events' do
            results = {
              'gmau_1' => 2,
              'gmau_2' => 3,
              'gmau_3' => 3
            }

            expect(aggregated_metrics_data).to eq(results)
          end
        end

        context 'hidden behind feature flag' do
          let(:enabled_feature_flag) { 'test_ff_enabled' }
          let(:disabled_feature_flag) { 'test_ff_disabled' }
          let(:aggregated_metrics) do
            [
              # represents stable aggregated metrics that has been fully released
              { name: 'gmau_without_ff', events: %w[event3_slot event5_slot], operator: "OR" },
              # represents new aggregated metric that is under performance testing on gitlab.com
              { name: 'gmau_enabled', events: %w[event4], operator: "AND", feature_flag: enabled_feature_flag },
              # represents aggregated metric that is under development and shouldn't be yet collected even on gitlab.com
              { name: 'gmau_disabled', events: %w[event4], operator: "AND", feature_flag: disabled_feature_flag }
            ].map(&:with_indifferent_access)
          end

          it 'returns the number of unique events for all known events' do
            skip_feature_flags_yaml_validation
            stub_feature_flags(enabled_feature_flag => true, disabled_feature_flag => false)

            expect(aggregated_metrics_data).to eq('gmau_without_ff' => 2, 'gmau_enabled' => 3)
          end
        end
      end
    end

    describe '.aggregated_metrics_weekly_data' do
      subject(:aggregated_metrics_data) { described_class.aggregated_metrics_weekly_data }

      before do
        described_class.track_event(entity1, 'event1_slot', 2.days.ago)
        described_class.track_event(entity2, 'event1_slot', 2.days.ago)
        described_class.track_event(entity3, 'event1_slot', 2.days.ago)
        described_class.track_event(entity1, 'event2_slot', 2.days.ago)
        described_class.track_event(entity2, 'event2_slot', 3.days.ago)
        described_class.track_event(entity3, 'event2_slot', 3.days.ago)
        described_class.track_event(entity1, 'event3_slot', 3.days.ago)
        described_class.track_event(entity2, 'event3_slot', 3.days.ago)
        described_class.track_event(entity2, 'event5_slot', 3.days.ago)

        # events out of time scope
        described_class.track_event(entity3, 'event2_slot', 8.days.ago)

        # events in different slots
        described_class.track_event(entity1, 'event4', 2.days.ago)
        described_class.track_event(entity2, 'event4', 2.days.ago)
        described_class.track_event(entity4, 'event4', 2.days.ago)
      end

      it_behaves_like 'aggregated_metrics_data'
    end

    describe '.aggregated_metrics_monthly_data' do
      subject(:aggregated_metrics_data) { described_class.aggregated_metrics_monthly_data }

      it_behaves_like 'aggregated_metrics_data' do
        before do
          described_class.track_event(entity1, 'event1_slot', 2.days.ago)
          described_class.track_event(entity2, 'event1_slot', 2.days.ago)
          described_class.track_event(entity3, 'event1_slot', 2.days.ago)
          described_class.track_event(entity1, 'event2_slot', 2.days.ago)
          described_class.track_event(entity2, 'event2_slot', 3.days.ago)
          described_class.track_event(entity3, 'event2_slot', 3.days.ago)
          described_class.track_event(entity1, 'event3_slot', 3.days.ago)
          described_class.track_event(entity2, 'event3_slot', 10.days.ago)
          described_class.track_event(entity2, 'event5_slot', 4.weeks.ago.advance(days: 1))

          # events out of time scope
          described_class.track_event(entity1, 'event5_slot', 4.weeks.ago.advance(days: -1))

          # events in different slots
          described_class.track_event(entity1, 'event4', 2.days.ago)
          described_class.track_event(entity2, 'event4', 2.days.ago)
          described_class.track_event(entity4, 'event4', 2.days.ago)
        end
      end

      context 'Redis calls' do
        let(:aggregated_metrics) do
          [
            { name: 'gmau_3', events: %w[event1_slot event2_slot event3_slot event5_slot], operator: "AND" }
          ].map(&:with_indifferent_access)
        end

        let(:known_events) do
          [
            { name: 'event1_slot', redis_slot: "slot", category: 'category1', aggregation: "weekly" },
            { name: 'event2_slot', redis_slot: "slot", category: 'category2', aggregation: "weekly" },
            { name: 'event3_slot', redis_slot: "slot", category: 'category3', aggregation: "weekly" },
            { name: 'event5_slot', redis_slot: "slot", category: 'category4', aggregation: "weekly" }
          ].map(&:with_indifferent_access)
        end

        it 'caches intermediate operations' do
          allow(described_class).to receive(:known_events).and_return(known_events)
          allow(described_class).to receive(:aggregated_metrics).and_return(aggregated_metrics)

          4.downto(1) do |subset_size|
            known_events.combination(subset_size).each do |events|
              keys = described_class.send(:weekly_redis_keys, events: events, start_date: 4.weeks.ago.to_date, end_date: Date.current)
              expect(Gitlab::Redis::HLL).to receive(:count).with(keys: keys).once.and_return(0)
            end
          end

          subject
        end
      end
    end
  end
end
