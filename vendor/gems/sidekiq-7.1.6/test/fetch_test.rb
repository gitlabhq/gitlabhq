# frozen_string_literal: true

require_relative "helper"
require "sidekiq/fetch"
require "sidekiq/capsule"
require "sidekiq/api"

describe Sidekiq::BasicFetch do
  before do
    @config = reset!
    @cap = @config.default_capsule
    @config.redis do |conn|
      conn.rpush("queue:basic", "msg")
    end
  end

  it "retrieves" do
    @cap.queues = ["basic", "bar,3"]
    fetch = Sidekiq::BasicFetch.new(@cap)

    uow = fetch.retrieve_work
    refute_nil uow
    assert_equal "basic", uow.queue_name
    assert_equal "msg", uow.job
    q = Sidekiq::Queue.new("basic")
    assert_equal 0, q.size
    uow.requeue
    assert_equal 1, q.size
    assert_nil uow.acknowledge
  end

  it "retrieves with strict ordering" do
    @cap.queues = ["basic", "bar"]
    fetch = Sidekiq::BasicFetch.new(@cap)
    cmd = fetch.queues_cmd
    assert_equal cmd, ["queue:basic", "queue:bar"]
  end

  it "bulk requeues" do
    @config.redis do |conn|
      conn.rpush("queue:foo", ["bob", "bar"])
      conn.rpush("queue:bar", "widget")
    end

    q1 = Sidekiq::Queue.new("foo")
    q2 = Sidekiq::Queue.new("bar")
    assert_equal 2, q1.size
    assert_equal 1, q2.size

    @cap.queues = ["foo", "bar"]
    fetch = Sidekiq::BasicFetch.new(@cap)
    works = 3.times.map { fetch.retrieve_work }
    assert_equal 0, q1.size
    assert_equal 0, q2.size

    fetch.bulk_requeue(works)
    assert_equal 2, q1.size
    assert_equal 1, q2.size
  end

  it "sleeps when no queues are active" do
    @cap.queues = []
    fetch = Sidekiq::BasicFetch.new(@cap)
    mock = Minitest::Mock.new
    mock.expect(:call, nil, [Sidekiq::BasicFetch::TIMEOUT])
    fetch.stub(:sleep, mock) { assert_nil fetch.retrieve_work }
    mock.verify
  end
end
