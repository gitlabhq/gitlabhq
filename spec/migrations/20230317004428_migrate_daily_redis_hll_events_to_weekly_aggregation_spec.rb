# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe MigrateDailyRedisHllEventsToWeeklyAggregation, :migration, :clean_gitlab_redis_cache, feature_category: :service_ping do
  it 'calls HLLRedisCounter.known_events to get list of events' do
    expect(Gitlab::UsageDataCounters::HLLRedisCounter).to receive(:known_events).and_call_original.at_least(1).time

    migrate!
  end

  describe '#redis_key' do
    let(:date) { Date.today }

    context 'with daily aggregation' do
      let(:date_formatted) { date.strftime('%G-%j') }
      let(:event) { { aggregation: 'daily', name: 'wiki_action' } }

      it 'returns correct key' do
        existing_key = "#{date_formatted}-{hll_counters}_wiki_action"

        expect(described_class.new.redis_key(event, date, event[:aggregation])).to eq(existing_key)
      end
    end

    context 'with weekly aggregation' do
      let(:event) { { aggregation: 'weekly', name: 'wiki_action' } }

      it 'returns correct key' do
        existing_key = Gitlab::UsageDataCounters::HLLRedisCounter.send(:redis_key, event, date)

        expect(described_class.new.redis_key(event, date, event[:aggregation])).to eq(existing_key)
      end
    end
  end

  context 'with weekly events' do
    let(:events) { [{ aggregation: 'weekly', name: 'wiki_action' }] }

    before do
      allow(Gitlab::UsageDataCounters::HLLRedisCounter).to receive(:known_events).and_return(events)
    end

    it 'does not migrate weekly events' do
      Gitlab::Redis::SharedState.with do |redis|
        expect(redis).not_to receive(:pfmerge)
        expect(redis).not_to receive(:expire)
      end

      migrate!
    end
  end

  context 'with daily events' do
    let(:daily_expiry) { Gitlab::UsageDataCounters::HLLRedisCounter::DEFAULT_DAILY_KEY_EXPIRY_LENGTH }
    let(:weekly_expiry) { Gitlab::UsageDataCounters::HLLRedisCounter::DEFAULT_WEEKLY_KEY_EXPIRY_LENGTH }

    it 'doesnt override events from migrated keys (code deployed before migration)' do
      events = [{ aggregation: 'daily', name: 'users_viewing_analytics' },
        { aggregation: 'weekly', name: 'users_viewing_analytics' }]
      allow(Gitlab::UsageDataCounters::HLLRedisCounter).to receive(:known_events).and_return(events)

      day = (Date.today - 1.week).beginning_of_week
      daily_event = events.first
      key_daily1 = Gitlab::UsageDataCounters::HLLRedisCounter.send(:redis_key, daily_event, day)
      Gitlab::Redis::HLL.add(key: key_daily1, value: 1, expiry: daily_expiry)
      key_daily2 = Gitlab::UsageDataCounters::HLLRedisCounter.send(:redis_key, daily_event, day + 2.days)
      Gitlab::Redis::HLL.add(key: key_daily2, value: 2, expiry: daily_expiry)
      key_daily3 = Gitlab::UsageDataCounters::HLLRedisCounter.send(:redis_key, daily_event, day + 5.days)
      Gitlab::Redis::HLL.add(key: key_daily3, value: 3, expiry: daily_expiry)

      # the same event but with weekly aggregation and pre-Redis migration
      weekly_event = events.second
      key_weekly = Gitlab::UsageDataCounters::HLLRedisCounter.send(:redis_key, weekly_event, day + 5.days)
      Gitlab::Redis::HLL.add(key: key_weekly, value: 3, expiry: weekly_expiry)

      migrate!

      expect(Gitlab::Redis::HLL.count(keys: key_weekly)).to eq(3)
    end

    it 'migrates with correct parameters', :aggregate_failures do
      events = [{ aggregation: 'daily', name: 'users_viewing_analytics_group_devops_adoption' }]
      allow(Gitlab::UsageDataCounters::HLLRedisCounter).to receive(:known_events).and_return(events)

      event = events.first.dup.tap { |e| e[:aggregation] = 'weekly' }
      # For every day in the last 30 days, add a value to the daily key with daily expiry (including today)
      31.times do |i|
        key = Gitlab::UsageDataCounters::HLLRedisCounter.send(:redis_key, event, Date.today - i.days)
        Gitlab::Redis::HLL.add(key: key, value: i, expiry: daily_expiry)
      end

      migrate!

      new_key = Gitlab::UsageDataCounters::HLLRedisCounter.send(:redis_key, event, Date.today)
      # for the current week we should have value eq to the day of the week (ie. 1 for Monday, 2 for Tuesday, etc.)
      first_week_days = Date.today.cwday
      expect(Gitlab::Redis::HLL.count(keys: new_key)).to eq(first_week_days)
      expect(with_redis { |r| r.ttl(new_key) }).to be_within(600).of(weekly_expiry)

      full_weeks = (31 - first_week_days) / 7
      # for the next full weeks we should have value eq to 7 (ie. 7 days in a week)
      (1..full_weeks).each do |i|
        new_key = Gitlab::UsageDataCounters::HLLRedisCounter.send(:redis_key, event, Date.today - i.weeks)
        expect(Gitlab::Redis::HLL.count(keys: new_key)).to eq(7)
        expect(with_redis { |r| r.ttl(new_key) }).to be_within(600).of(weekly_expiry)
      end

      # for the last week we should have value eq to amount of rest of the days affected
      last_week_days = 31 - ((full_weeks * 7) + first_week_days)
      unless last_week_days.zero?
        last_week = full_weeks + 1
        new_key = Gitlab::UsageDataCounters::HLLRedisCounter.send(:redis_key, event, Date.today - last_week.weeks)
        expect(Gitlab::Redis::HLL.count(keys: new_key)).to eq(last_week_days)
        expect(with_redis { |r| r.ttl(new_key) }).to be_within(600).of(weekly_expiry)
      end
    end
  end

  def with_redis(&block)
    Gitlab::Redis::SharedState.with(&block)
  end
end
