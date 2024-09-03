# frozen_string_literal: true

require_relative "helper"
require "sidekiq/api"
require "active_support/core_ext/numeric/time"

class MySetJob
  include Sidekiq::Job
  queue_as :foo
  sidekiq_options "retry" => 12
  def perform
  end
end

class MyCustomJob
  include Sidekiq::Job

  def perform(recorder)
    $my_recorder << ["work_performed"]
  end
end

class MyCustomMiddleware
  def initialize(name, recorder)
    @name = name
    @recorder = recorder
  end

  def call(*args)
    @recorder << "#{@name}-before"
    response = yield
    @recorder << "#{@name}-after"
    response
  end
end

describe Sidekiq::Job do
  before do
    @config = reset!
  end

  describe "#set" do
    it "provides basic ActiveJob compatibilility" do
      q = Sidekiq::ScheduledSet.new
      assert_equal 0, q.size
      jid = MySetJob.set(wait_until: 1.hour.from_now).perform_async(123)
      assert jid
      assert_equal 1, q.size
      jid = MySetJob.set(wait: 1.hour).perform_async(123)
      assert jid
      assert_equal 2, q.size

      q = Sidekiq::Queue.new("foo")
      assert_equal 0, q.size
      MySetJob.perform_async
      MySetJob.perform_inline
      MySetJob.perform_sync
      assert_equal 1, q.size

      MySetJob.set(queue: "xyz").perform_async
      assert_equal 1, Sidekiq::Queue.new("xyz").size
    end

    it "can be memoized" do
      q = Sidekiq::Queue.new("bar")
      assert_equal 0, q.size
      set = MySetJob.set(queue: :bar, foo: "qaaz")
      set.perform_async(1)
      set.perform_async(1)
      set.perform_async(1)
      set.perform_async(1)
      assert_equal 4, q.size
      assert_equal 4, q.map { |j| j["jid"] }.uniq.size
      set.perform_in(10, 1)
    end

    it "allows option overrides" do
      q = Sidekiq::Queue.new("bar")
      assert_equal 0, q.size
      assert MySetJob.set(queue: :bar).perform_async(1)
      job = q.first
      assert_equal "bar", job["queue"]
      assert_equal 12, job["retry"]
    end

    it "handles symbols and strings" do
      q = Sidekiq::Queue.new("bar")
      assert_equal 0, q.size
      assert MySetJob.set("queue" => "bar", :retry => 11).perform_async(1)
      job = q.first
      assert_equal "bar", job["queue"]
      assert_equal 11, job["retry"]

      q.clear
      assert MySetJob.perform_async(1)
      assert_equal 0, q.size

      q = Sidekiq::Queue.new("foo")
      job = q.first
      assert_equal "foo", job["queue"]
      assert_equal 12, job["retry"]
    end

    it "allows multiple calls" do
      MySetJob.set(queue: :foo).set(bar: "xyz").perform_async

      q = Sidekiq::Queue.new("foo")
      job = q.first
      assert_equal "foo", job["queue"]
      assert_equal "xyz", job["bar"]
    end

    it "works with .perform_bulk" do
      q = Sidekiq::Queue.new("bar")
      assert_equal 0, q.size

      set = MySetJob.set(queue: "bar")
      jids = set.perform_bulk((1..1_001).to_a.map { |x| Array(x) })

      assert_equal 1_001, q.size
      assert_equal 1_001, jids.size
    end

    describe ".perform_bulk and lazy enumerators" do
      it "evaluates lazy enumerators" do
        q = Sidekiq::Queue.new("bar")
        assert_equal 0, q.size

        set = MySetJob.set("queue" => "bar")
        lazy_args = (1..1_001).to_a.map { |x| Array(x) }.lazy
        jids = set.perform_bulk(lazy_args)

        assert_equal 1_001, q.size
        assert_equal 1_001, jids.size
      end
    end
  end

  describe "#perform_inline" do
    $my_recorder = []

    it "executes middleware & runs job inline" do
      @config.server_middleware.add MyCustomMiddleware, "1-server", $my_recorder
      @config.client_middleware.add MyCustomMiddleware, "1-client", $my_recorder
      MyCustomJob.perform_inline($my_recorder)
      assert_equal $my_recorder.flatten, %w[1-client-before 1-client-after 1-server-before work_performed 1-server-after]
    end
  end
end
