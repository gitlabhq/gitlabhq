# frozen_string_literal: true

require_relative "helper"
require "sidekiq/capsule"

describe Sidekiq::Capsule do
  before do
    @config = reset!
    @cap = @config.default_capsule
  end

  it "provides its own redis pool" do
    one = @cap
    one.concurrency = 2
    two = Sidekiq::Capsule.new("foo", @config)
    two.concurrency = 3

    # the pool is cached
    assert_equal one.redis_pool, one.redis_pool
    assert_equal two.redis_pool, two.redis_pool
    # they are sized correctly
    assert_equal 2, one.redis_pool.size
    assert_equal 3, two.redis_pool.size
    refute_equal one.redis_pool, two.redis_pool

    # they point to the same Redis
    assert one.redis { |c| c.set("hello", "world") }
    assert_equal "world", two.redis { |c| c.get("hello") }
  end

  it "parses queues correctly" do
    cap = @cap
    assert_equal ["default"], cap.queues

    cap.queues = %w[foo bar,2]
    assert_equal %w[foo bar bar], cap.queues

    cap.queues = ["default"]
    assert_equal %w[default], cap.queues

    # config/sidekiq.yml input will look like this
    cap.queues = [["foo"], ["baz", 3]]
    assert_equal %w[foo baz baz baz], cap.queues
  end

  it "parses weights correctly" do
    cap = @cap
    assert_equal({"default" => 0}, cap.weights)

    cap.queues = %w[foo bar,2]
    assert_equal({"foo" => 0, "bar" => 2}, cap.weights)

    cap.queues = ["default"]
    assert_equal({"default" => 0}, cap.weights)

    # config/sidekiq.yml input will look like this
    cap.queues = [["foo"], ["baz", 3]]
    assert_equal({"foo" => 0, "baz" => 3}, cap.weights)
  end

  it "can have customized middleware chains" do
    one = Object.new
    two = Object.new
    @config.client_middleware.add one
    @config.server_middleware.add one
    assert_includes @config.client_middleware, one
    assert_includes @config.server_middleware, one

    @config.capsule("testy") do |cap|
      cap.concurrency = 2
      cap.queues = %w[foo bar,2]
      cap.server_middleware do |chain|
        chain.add two
      end
      cap.client_middleware do |chain|
        chain.add two
      end
    end

    assert_equal 2, @config.capsules.size
    assert_equal %w[default testy], @config.capsules.values.map(&:name).sort
    assert_equal %w[default testy], @config.capsules.keys.sort
    assert_equal 7, @config.total_concurrency
    cap = @config.capsule("testy")
    cap1 = @config.capsule(:testy)
    assert cap
    assert_equal cap, cap1
    assert_includes cap.server_middleware, one
    assert_includes cap.client_middleware, one
    assert_includes cap.server_middleware, two
    assert_includes cap.client_middleware, two
    refute_includes @config.server_middleware, two
    refute_includes @config.client_middleware, two
  end
end
