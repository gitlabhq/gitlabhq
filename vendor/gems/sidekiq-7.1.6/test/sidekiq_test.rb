# frozen_string_literal: true

require_relative "helper"

describe Sidekiq do
  before do
    @config = reset!
  end

  describe "json processing" do
    it "handles json" do
      assert_equal({"foo" => "bar"}, Sidekiq.load_json("{\"foo\":\"bar\"}"))
      assert_equal "{\"foo\":\"bar\"}", Sidekiq.dump_json({"foo" => "bar"})
    end
  end

  describe "redis connection" do
    it "returns error without creating a connection if block is not given" do
      assert_raises(ArgumentError) do
        @config.redis
      end
    end
  end

  describe "lifecycle events" do
    it "handles invalid input" do
      @config[:lifecycle_events][:startup].clear

      e = assert_raises ArgumentError do
        @config.on(:startp)
      end
      assert_match(/Invalid event name/, e.message)
      e = assert_raises ArgumentError do
        @config.on("startup")
      end
      assert_match(/Symbols only/, e.message)
      @config.on(:startup) do
        1 + 1
      end

      assert_equal 2, @config[:lifecycle_events][:startup].first.call
    end
  end

  describe "default_job_options" do
    it "stringifies keys" do
      @old_options = Sidekiq.default_job_options
      begin
        Sidekiq.default_job_options = {queue: "cat"}
        assert_equal "cat", Sidekiq.default_job_options["queue"]
      ensure
        Sidekiq.default_job_options = @old_options
      end
    end
  end

  describe "error handling" do
    it "deals with user-specified error handlers which raise errors" do
      output = capture_logging(@config) do
        @config.error_handlers << proc { |x, hash|
          raise "boom"
        }
        @config.handle_exception(RuntimeError.new("hello"))
      ensure
        @config.error_handlers.pop
      end
      assert_includes output, "boom"
      assert_includes output, "ERROR"
    end
  end

  describe "redis connection" do
    it "does not continually retry" do
      assert_raises Sidekiq::RedisClientAdapter::CommandError do
        @config.redis do |c|
          raise Sidekiq::RedisClientAdapter::CommandError, "READONLY You can't write against a replica."
        end
      end
    end

    it "reconnects if connection is flagged as readonly" do
      counts = []
      @config.redis do |c|
        counts << c.incr("connections").to_i
        raise Sidekiq::RedisClientAdapter::CommandError, "READONLY You can't write against a replica." if counts.size == 1
      end
      assert_equal 2, counts.size
      assert_equal counts[0] + 1, counts[1]
    end

    it "reconnects if instance state changed" do
      counts = []
      @config.redis do |c|
        counts << c.incr("connections").to_i
        raise Sidekiq::RedisClientAdapter::CommandError, "UNBLOCKED force unblock from blocking operation, instance state changed (master -> replica?)" if counts.size == 1
      end
      assert_equal 2, counts.size
      assert_equal counts[0] + 1, counts[1]
    end
  end

  describe "redis info" do
    it "calls the INFO command which returns at least redis_version" do
      output = @config.redis_info
      assert_includes output.keys, "redis_version"
    end
  end
end
