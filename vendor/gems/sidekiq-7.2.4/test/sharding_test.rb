# frozen_string_literal: true

require_relative "helper"
require "sidekiq"
require "sidekiq/api"

class ShardJob
  include Sidekiq::Job
end

class ShardMiddleware
  include Sidekiq::ClientMiddleware
  def call(wrkr, job, q, pool)
    # set a flag so we can inspect which shard is active
    redis { |c| c.set("flag", job["jid"]) }
    fl = pool.with { |c| c.get("flag") }
    raise "Pool and redis are out of sync!" if fl != job["jid"]
    yield
  end
end

describe "Sharding" do
  before do
    @config = reset!
    @sh1 = Sidekiq::RedisConnection.create(size: 1, db: 6)
    @sh2 = Sidekiq::RedisConnection.create(size: 1, db: 5)
  end

  after do
    @sh1.shutdown(&:close)
    @sh2.shutdown(&:close)
  end

  def flags
    [Sidekiq.redis_pool, @sh1, @sh2].map do |pool|
      pool.with { |c| c.get("flag") }
    end
  end

  describe "client" do
    it "redirects the middleware pool to the current shard" do
      @config.client_middleware.add ShardMiddleware

      jid1 = nil
      Sidekiq::Client.via(@sh1) do
        jid1 = ShardJob.perform_async
        assert_equal [jid1, jid1, nil], flags
      end
      assert_equal [nil, jid1, nil], flags

      jid2 = nil
      Sidekiq::Client.via(@sh2) do
        jid2 = ShardJob.perform_async
        assert_equal [jid2, jid1, jid2], flags
      end
      assert_equal [nil, jid1, jid2], flags
    end

    it "routes jobs to the proper shard" do
      q = Sidekiq::Queue.new
      ss = Sidekiq::ScheduledSet.new
      assert_equal 0, q.size
      assert_equal 0, ss.size

      # redirect jobs with magic block
      Sidekiq::Client.via(@sh1) do
        assert_equal 0, q.size
        assert_equal 0, ss.size
        ShardJob.perform_async
        ShardJob.perform_in(3)
        assert_equal 1, q.size
        assert_equal 1, ss.size
      end

      Sidekiq::Client.via(@sh2) do
        assert_equal 0, ss.size
        assert_equal 0, q.size
      end

      # redirect jobs explicitly with pool attribute
      ShardJob.set(pool: @sh2).perform_async
      ShardJob.set(pool: @sh2).perform_in(4)
      Sidekiq::Client.via(@sh2) do
        assert_equal 1, q.size
        assert_equal 1, ss.size
      end

      assert_equal 0, ss.size
      assert_equal 0, q.size
    end
  end
end
