# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe PersistUsageDataKeysThatShouldNotExpire, :migration, :clean_gitlab_redis_cache, feature_category: :service_ping do
  def get_expiry_for_key(key)
    Gitlab::Redis::SharedState.with { |redis| redis.ttl(key) }
  end

  shared_examples 'a Redis key does not expire' do |key|
    before do
      Gitlab::Redis::SharedState.with do |redis|
        redis.incr(key)
        redis.expire(key, 6.weeks)
      end
    end

    it 'removes the expiry date from the key' do
      migrate!

      expect(get_expiry_for_key(key)).to eq(-1)
    end
  end

  shared_examples 'a Redis key that expire' do |key|
    before do
      Gitlab::Redis::SharedState.with do |redis|
        redis.incr(key)
        redis.expire(key, 6.weeks)
      end
    end

    it 'does not remove the expiry date from the key' do
      migrate!

      expect(get_expiry_for_key(key)).to be > 0
    end
  end

  describe '#up' do
    it_behaves_like 'a Redis key does not expire', '{event_counters}_some_event'
    it_behaves_like 'a Redis key does not expire', '{event_counters}_some_other_event'
    it_behaves_like 'a Redis key does not expire', 'WEB_IDE_VIEWS_COUNT'
    it_behaves_like 'a Redis key that expire', 'some_non_legacy_key_without_the_right_prefix'
    it_behaves_like 'a Redis key that expire', '{hll_counters}_project_action-2024-18'
  end
end
