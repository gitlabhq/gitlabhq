# frozen_string_literal: true

RSpec.configure do |config|
  config.after(:each, :redis) do
    Sidekiq.redis do |connection|
      connection.redis.flushdb
    end
  end

  config.around(:each, :clean_gitlab_redis_cache) do |example|
    redis_cache_cleanup!

    example.run

    redis_cache_cleanup!
  end

  config.around(:each, :clean_gitlab_redis_shared_state) do |example|
    redis_shared_state_cleanup!

    example.run

    redis_shared_state_cleanup!
  end

  config.around(:each, :clean_gitlab_redis_queues) do |example|
    redis_queues_cleanup!

    example.run

    redis_queues_cleanup!
  end

  config.around(:each, :clean_gitlab_redis_trace_chunks) do |example|
    redis_trace_chunks_cleanup!

    example.run

    redis_trace_chunks_cleanup!
  end
end
