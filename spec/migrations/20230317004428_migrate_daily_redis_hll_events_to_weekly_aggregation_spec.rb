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
      let(:event) { { name: 'g_edit_by_web_ide' } }

      it 'returns correct key' do
        existing_key = "#{date_formatted}-{hll_counters}_g_edit_by_web_ide"

        expect(described_class.new.redis_key(event, date, :daily)).to eq(existing_key)
      end
    end

    context 'with weekly aggregation' do
      let(:date_formatted) { date.strftime('%G-%V') }
      let(:event) { { name: 'weekly_action' } }

      it 'returns correct key' do
        existing_key = "{hll_counters}_weekly_action-#{date_formatted}"

        expect(described_class.new.redis_key(event, date, :weekly)).to eq(existing_key)
      end
    end
  end

  context 'with weekly events' do
    let(:events) { [{ name: 'weekly_action' }] }

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
    let(:daily_expiry) { 29.days }
    let(:weekly_expiry) { Gitlab::UsageDataCounters::HLLRedisCounter::KEY_EXPIRY_LENGTH }

    it 'migrates with correct parameters', :aggregate_failures do
      event = { name: 'g_project_management_epic_blocked_removed' }
      allow(Gitlab::UsageDataCounters::HLLRedisCounter).to receive(:known_events).and_return([event])

      # For every day in the last 30 days, add a value to the daily key with daily expiry (including today)
      31.times do |i|
        key = described_class.new.send(:redis_key, event, Date.today - i.days, :weekly)
        Gitlab::Redis::HLL.add(key: key, value: i, expiry: daily_expiry)
      end

      migrate!

      new_key = described_class.new.send(:redis_key, event, Date.today, :weekly)
      # for the current week we should have value eq to the day of the week (ie. 1 for Monday, 2 for Tuesday, etc.)
      first_week_days = Date.today.cwday
      expect(Gitlab::Redis::HLL.count(keys: new_key)).to eq(first_week_days)
      expect(with_redis { |r| r.ttl(new_key) }).to be_within(600).of(weekly_expiry)

      full_weeks = (31 - first_week_days) / 7
      # for the next full weeks we should have value eq to 7 (ie. 7 days in a week)
      (1..full_weeks).each do |i|
        new_key = described_class.new.send(:redis_key, event, Date.today - i.weeks, :weekly)
        expect(Gitlab::Redis::HLL.count(keys: new_key)).to eq(7)
        expect(with_redis { |r| r.ttl(new_key) }).to be_within(600).of(weekly_expiry)
      end

      # for the last week we should have value eq to amount of rest of the days affected
      last_week_days = 31 - ((full_weeks * 7) + first_week_days)
      unless last_week_days.zero?
        last_week = full_weeks + 1
        new_key = described_class.new.send(:redis_key, event, Date.today - last_week.weeks, :weekly)
        expect(Gitlab::Redis::HLL.count(keys: new_key)).to eq(last_week_days)
        expect(with_redis { |r| r.ttl(new_key) }).to be_within(600).of(weekly_expiry)
      end
    end
  end

  def with_redis(&block)
    Gitlab::Redis::SharedState.with(&block)
  end
end
