RSpec.configure do |config|
  config.before(:each, :repository) do
    TestEnv.clean_test_path
  end

  config.before(:all, :broken_storage) do
    FileUtils.rm_rf Gitlab.config.repositories.storages.broken.legacy_disk_path
  end

  config.before(:each, :broken_storage) do
    allow(Gitlab::GitalyClient).to receive(:call) do
      raise GRPC::Unavailable.new('Gitaly broken in this spec')
    end

    # Track the maximum number of failures
    first_failure = Time.parse("2017-11-14 17:52:30")
    last_failure = Time.parse("2017-11-14 18:54:37")
    failure_count = Gitlab::CurrentSettings.circuitbreaker_failure_count_threshold + 1
    cache_key = "#{Gitlab::Git::Storage::REDIS_KEY_PREFIX}broken:#{Gitlab::Environment.hostname}"

    Gitlab::Git::Storage.redis.with do |redis|
      redis.pipelined do
        redis.zadd(Gitlab::Git::Storage::REDIS_KNOWN_KEYS, 0, cache_key)
        redis.hset(cache_key, :first_failure, first_failure.to_i)
        redis.hset(cache_key, :last_failure, last_failure.to_i)
        redis.hset(cache_key, :failure_count, failure_count.to_i)
      end
    end
  end

  config.after(:each, :broken_storage) do
    Gitlab::Git::Storage.redis.with(&:flushall)
  end
end
