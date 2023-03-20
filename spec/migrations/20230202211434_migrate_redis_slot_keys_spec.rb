# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe MigrateRedisSlotKeys, :migration, feature_category: :service_ping do
  let(:date) { Date.yesterday.strftime('%G-%j') }
  let(:week) { Date.yesterday.strftime('%G-%V') }

  before do
    allow(described_class::BackupHLLRedisCounter).to receive(:known_events).and_return([{
      redis_slot: 'analytics',
      aggregation: 'daily',
      name: 'users_viewing_analytics_group_devops_adoption'
    }, {
      aggregation: 'weekly',
      name: 'wiki_action'
    }])
  end

  describe "#up" do
    it 'rename keys', :aggregate_failures do
      expiry_daily = described_class::BackupHLLRedisCounter::DEFAULT_DAILY_KEY_EXPIRY_LENGTH
      expiry_weekly = described_class::BackupHLLRedisCounter::DEFAULT_WEEKLY_KEY_EXPIRY_LENGTH

      default_slot = described_class::BackupHLLRedisCounter::REDIS_SLOT

      old_slot_a = "#{date}-users_viewing_{analytics}_group_devops_adoption"
      old_slot_b = "{wiki_action}-#{week}"

      new_slot_a = "#{date}-{#{default_slot}}_users_viewing_analytics_group_devops_adoption"
      new_slot_b = "{#{default_slot}}_wiki_action-#{week}"

      Gitlab::Redis::HLL.add(key: old_slot_a, value: 1, expiry: expiry_daily)
      Gitlab::Redis::HLL.add(key: old_slot_b, value: 1, expiry: expiry_weekly)

      # check that we merge values during migration
      # i.e. we dont drop keys created after code deploy but before the migration
      Gitlab::Redis::HLL.add(key: new_slot_a, value: 2, expiry: expiry_daily)
      Gitlab::Redis::HLL.add(key: new_slot_b, value: 2, expiry: expiry_weekly)

      migrate!

      expect(Gitlab::Redis::HLL.count(keys: new_slot_a)).to eq(2)
      expect(Gitlab::Redis::HLL.count(keys: new_slot_b)).to eq(2)
      expect(with_redis { |r| r.ttl(new_slot_a) }).to be_within(600).of(expiry_daily)
      expect(with_redis { |r| r.ttl(new_slot_b) }).to be_within(600).of(expiry_weekly)
    end
  end

  def with_redis(&block)
    Gitlab::Redis::SharedState.with(&block)
  end
end
