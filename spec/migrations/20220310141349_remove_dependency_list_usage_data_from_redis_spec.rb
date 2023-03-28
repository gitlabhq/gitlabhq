# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe RemoveDependencyListUsageDataFromRedis, :migration, :clean_gitlab_redis_shared_state,
  feature_category: :dependency_management do
  let(:key) { "DEPENDENCY_LIST_USAGE_COUNTER" }

  describe "#up" do
    it 'removes the hash from redis' do
      with_redis do |redis|
        redis.hincrby(key, 1, 1)
        redis.hincrby(key, 2, 1)
      end

      expect { migrate! }.to change { with_redis { |r| r.hgetall(key) } }.from({ '1' => '1', '2' => '1' }).to({})
    end
  end

  def with_redis(&block)
    Gitlab::Redis::SharedState.with(&block)
  end
end
