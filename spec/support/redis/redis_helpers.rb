# frozen_string_literal: true

module RedisHelpers
  # config/README.md

  # Usage: performance enhancement
  def redis_cache_cleanup!
    Gitlab::Redis::Cache.with(&:flushall)
  end

  # Usage: SideKiq, Mailroom, CI Runner, Workhorse, push services
  def redis_queues_cleanup!
    Gitlab::Redis::Queues.with(&:flushall)
  end

  # Usage: session state, rate limiting
  def redis_shared_state_cleanup!
    Gitlab::Redis::SharedState.with(&:flushall)
  end
end
