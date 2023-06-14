# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe ReMigrateRedisSlotKeys, :migration, feature_category: :service_ping do
  let(:date) { Date.yesterday.strftime('%G-%j') }
  let(:week) { Date.yesterday.strftime('%G-%V') }
  let(:known_events) do
    [
      {
        redis_slot: 'management',
        name: 'g_project_management_epic_closed'
      }, {
        name: 'incident_management_incident_assigned' # weekly event
      },
      {
        name: 'non_existing_event'
      }, {
        name: 'event_without_expiry'
      }
    ]
  end

  describe "#up" do
    it 'rename keys', :aggregate_failures do
      allow(Gitlab::UsageDataCounters::HLLRedisCounter).to receive(:known_events)
                                                             .and_return(known_events)

      expiry_daily = 29.days
      expiry_weekly = described_class::KEY_EXPIRY_LENGTH

      default_slot = Gitlab::UsageDataCounters::HLLRedisCounter::REDIS_SLOT

      old_slot_a = "#{date}-g_project_{management}_epic_closed"
      old_slot_b = "{incident_management_incident_assigned}-#{week}"
      old_slot_without_expiry = "{event_without_expiry}-#{week}"

      new_slot_a = "#{date}-{#{default_slot}}_g_project_management_epic_closed"
      new_slot_b = "{#{default_slot}}_incident_management_incident_assigned-#{week}"
      new_slot_without_expiry = "{#{default_slot}}_event_without_expiry-#{week}"

      Gitlab::Redis::HLL.add(key: old_slot_a, value: 1, expiry: expiry_daily)
      Gitlab::Redis::HLL.add(key: old_slot_b, value: 1, expiry: expiry_weekly)
      Gitlab::Redis::HLL.add(key: old_slot_a, value: 2, expiry: expiry_daily)
      Gitlab::Redis::HLL.add(key: old_slot_b, value: 2, expiry: expiry_weekly)
      Gitlab::Redis::HLL.add(key: old_slot_b, value: 2, expiry: expiry_weekly)
      Gitlab::Redis::SharedState.with { |redis| redis.pfadd(old_slot_without_expiry, 1) }

      # check that we merge values during migration
      # i.e. we dont drop keys created after code deploy but before the migration
      Gitlab::Redis::HLL.add(key: new_slot_a, value: 3, expiry: expiry_daily)
      Gitlab::Redis::HLL.add(key: new_slot_b, value: 3, expiry: expiry_weekly)
      Gitlab::Redis::HLL.add(key: new_slot_without_expiry, value: 2, expiry: expiry_weekly)

      migrate!

      expect(Gitlab::Redis::HLL.count(keys: new_slot_a)).to eq(3)
      expect(Gitlab::Redis::HLL.count(keys: new_slot_b)).to eq(3)
      expect(Gitlab::Redis::HLL.count(keys: new_slot_without_expiry)).to eq(2)
      expect(with_redis { |r| r.ttl(new_slot_a) }).to be_within(600).of(expiry_daily)
      expect(with_redis { |r| r.ttl(new_slot_b) }).to be_within(600).of(expiry_weekly)
      expect(with_redis { |r| r.ttl(new_slot_without_expiry) }).to be_within(600).of(expiry_weekly)
    end

    it 'runs without errors' do
      expect { migrate! }.not_to raise_error
    end
  end

  def with_redis(&block)
    Gitlab::Redis::SharedState.with(&block)
  end
end
