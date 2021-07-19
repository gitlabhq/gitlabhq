# frozen_string_literal: true

module RedisHelpers
  # config/README.md

  # Usage: performance enhancement
  def redis_cache_cleanup!
    Gitlab::Redis::Cache.with(&:flushdb)
  end

  # Usage: SideKiq, Mailroom, CI Runner, Workhorse, push services
  def redis_queues_cleanup!
    Gitlab::Redis::Queues.with(&:flushdb)
  end

  # Usage: session state, rate limiting
  def redis_shared_state_cleanup!
    Gitlab::Redis::SharedState.with(&:flushdb)
  end

  # Usage: CI trace chunks
  def redis_trace_chunks_cleanup!
    Gitlab::Redis::TraceChunks.with(&:flushdb)
  end
end
