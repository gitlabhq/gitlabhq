# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe ChangeICodeReviewCreateMrKeysFromRedisHllToRedis, :migration, :clean_gitlab_redis_cache, feature_category: :service_ping do
  def set_redis_hll(key, value)
    Gitlab::Redis::HLL.add(key: key, value: value, expiry: 6.weeks)
  end

  def get_int_from_redis(key)
    Gitlab::Redis::SharedState.with { |redis| redis.get(key)&.to_i }
  end

  describe "#up" do
    before do
      set_redis_hll('{hll_counters}_i_code_review_create_mr-2023-16', value: 1)
      set_redis_hll('{hll_counters}_i_code_review_create_mr-2023-16', value: 2)
      set_redis_hll('{hll_counters}_i_code_review_create_mr-2023-47', value: 3)
      set_redis_hll('{hll_counters}_i_code_review_create_mr-2023-48', value: 1)
      set_redis_hll('{hll_counters}_i_code_review_create_mr-2023-49', value: 2)
      set_redis_hll('{hll_counters}_i_code_review_create_mr-2023-49', value: 4)
      set_redis_hll('{hll_counters}_some_other_event-2023-49', value: 7)
    end

    it 'migrates all RedisHLL keys for i_code_review_create_mr', :aggregate_failures do
      migrate!

      expect(get_int_from_redis('{event_counters}_i_code_review_user_create_mr-2023-16')).to eq(2)
      expect(get_int_from_redis('{event_counters}_i_code_review_user_create_mr-2023-47')).to eq(1)
      expect(get_int_from_redis('{event_counters}_i_code_review_user_create_mr-2023-48')).to eq(1)
      expect(get_int_from_redis('{event_counters}_i_code_review_user_create_mr-2023-49')).to eq(2)
    end

    it 'does not not migrate other RedisHLL keys' do
      migrate!

      expect(get_int_from_redis('{event_counters}_some_other_event-2023-16')).to be_nil
    end
  end
end
