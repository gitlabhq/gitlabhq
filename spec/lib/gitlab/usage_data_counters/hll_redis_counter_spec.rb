# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::UsageDataCounters::HLLRedisCounter, :clean_gitlab_redis_shared_state do
  let(:entity1) { 'dfb9d2d2-f56c-4c77-8aeb-6cddc4a1f857' }
  let(:entity2) { '1dd9afb2-a3ee-4de1-8ae3-a405579c8584' }
  let(:entity3) { '34rfjuuy-ce56-sa35-ds34-dfer567dfrf2' }
  let(:entity4) { '8b9a2671-2abf-4bec-a682-22f6a8f7bf31' }

  let(:weekly_event) { 'g_analytics_contribution' }
  let(:daily_event) { 'g_analytics_search' }
  let(:analytics_slot_event) { 'g_analytics_contribution' }
  let(:compliance_slot_event) { 'g_compliance_dashboard' }
  let(:category_analytics) { 'g_analytics_search' }
  let(:category_productivity) { 'g_analytics_productivity' }
  let(:no_slot) { 'no_slot' }
  let(:different_aggregation) { 'different_aggregation' }
  let(:custom_daily_event) { 'g_analytics_custom' }

  let(:known_events) do
    [
      { name: weekly_event, redis_slot: "analytics", category: "analytics", expiry: 84, aggregation: "weekly" },
      { name: daily_event, redis_slot: "analytics", category: "analytics", expiry: 84, aggregation: "daily" },
      { name: category_productivity, redis_slot: "analytics", category: "productivity", aggregation: "weekly" },
      { name: compliance_slot_event, redis_slot: "compliance", category: "compliance", aggregation: "weekly" },
      { name: no_slot, category: "global", aggregation: "daily" },
      { name: different_aggregation, category: "global", aggregation: "monthly" }
    ].map(&:with_indifferent_access)
  end

  before do
    allow(described_class).to receive(:known_events).and_return(known_events)
  end

  around do |example|
    # We need to freeze to a reference time
    # because visits are grouped by the week number in the year
    # Without freezing the time, the test may behave inconsistently
    # depending on which day of the week test is run.
    # Monday 6th of June
    reference_time = Time.utc(2020, 6, 1)
    Timecop.freeze(reference_time) { example.run }
  end

  describe '.track_event' do
    it "raise error if metrics don't have same aggregation" do
      expect { described_class.track_event(entity1, different_aggregation, Date.current) } .to raise_error(Gitlab::UsageDataCounters::HLLRedisCounter::UnknownAggregation)
    end

    it 'raise error if metrics of unknown aggregation' do
      expect { described_class.track_event(entity1, 'unknown', Date.current) } .to raise_error(Gitlab::UsageDataCounters::HLLRedisCounter::UnknownEvent)
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
      expect { described_class.unique_events(event_names: [compliance_slot_event, analytics_slot_event], start_date: 4.weeks.ago, end_date: Date.current) }.to raise_error('Events should be in same slot')
    end

    it 'raise error if metrics are not in the same category' do
      expect { described_class.unique_events(event_names: [category_analytics, category_productivity], start_date: 4.weeks.ago, end_date: Date.current) }.to raise_error('Events should be in same category')
    end

    it "raise error if metrics don't have same aggregation" do
      expect { described_class.unique_events(event_names: [daily_event, weekly_event], start_date: 4.weeks.ago, end_date: Date.current) }.to raise_error('Events should have same aggregation level')
    end

    context 'when data for the last complete week' do
      it { expect(described_class.unique_events(event_names: weekly_event, start_date: 1.week.ago, end_date: Date.current)).to eq(1) }
    end

    context 'when data for the last 4 complete weeks' do
      it { expect(described_class.unique_events(event_names: weekly_event, start_date: 4.weeks.ago, end_date: Date.current)).to eq(2) }
    end

    context 'when data for the week 4 weeks ago' do
      it { expect(described_class.unique_events(event_names: weekly_event, start_date: 4.weeks.ago, end_date: 3.weeks.ago)).to eq(1) }
    end

    context 'when using daily aggregation' do
      it { expect(described_class.unique_events(event_names: daily_event, start_date: 7.days.ago, end_date: Date.current)).to eq(2) }
      it { expect(described_class.unique_events(event_names: daily_event, start_date: 28.days.ago, end_date: Date.current)).to eq(3) }
      it { expect(described_class.unique_events(event_names: daily_event, start_date: 28.days.ago, end_date: 21.days.ago)).to eq(1) }
    end

    context 'when no slot is set' do
      it { expect(described_class.unique_events(event_names: no_slot, start_date: 7.days.ago, end_date: Date.current)).to eq(1) }
    end
  end
end
