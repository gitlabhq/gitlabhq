# frozen_string_literal: true

require_relative "helper"
require "sidekiq/cli"
require "sidekiq/fetch"
require "sidekiq/scheduled"
require "sidekiq/processor"
require "sidekiq/api"

class JoeJob
  include Sidekiq::Job
  def perform(slp)
    raise "boom" if slp == "boom"
    sleep(slp) if slp > 0
    $count += 1
  end
end

describe "Actors" do
  before do
    @config = reset!
    @cap = @config.default_capsule
  end

  describe "scheduler" do
    it "can start and stop" do
      f = Sidekiq::Scheduled::Poller.new(@config)
      f.start
      f.terminate
    end

    it "can schedule" do
      ss = Sidekiq::ScheduledSet.new
      q = Sidekiq::Queue.new

      JoeJob.perform_in(0.01, 0)

      assert_equal 0, q.size
      assert_equal 1, ss.size

      sleep 0.015
      s = Sidekiq::Scheduled::Poller.new(@config)
      s.enqueue
      assert_equal 1, q.size
      assert_equal 0, ss.size
      s.terminate
    end
  end

  describe "processor" do
    before do
      $count = 0
      @mutex = ::Mutex.new
      @cond = ::ConditionVariable.new
      @latest_error = nil
    end

    def result(pr, ex)
      @latest_error = ex
      @mutex.synchronize do
        @cond.signal
      end
      pr.job
    end

    def await(timeout = 0.5)
      @mutex.synchronize do
        yield
        @cond.wait(@mutex, timeout)
      end
    end

    it "can stop" do
      f = Sidekiq::Processor.new(@cap) { |p, ex| raise "should not raise!" }
      f.terminate
      assert_nil f.thread # didn't start it
    end

    it "deals with errors" do
      q = Sidekiq::Queue.new
      assert_equal 0, q.size
      pr = Sidekiq::Processor.new(@cap) do |prc, ex|
        result(prc, ex)
      end
      jid = JoeJob.perform_async("boom")
      assert jid, jid
      assert_equal 1, q.size

      a = $count
      await do
        pr.start
      end

      pr.kill(true)
      b = $count
      assert_equal a, b
      assert @latest_error
      assert_equal false, pr.thread.status
      assert_equal "boom", @latest_error.message
      assert_equal RuntimeError, @latest_error.class
    end

    it "gracefully kills" do
      q = Sidekiq::Queue.new
      assert_equal 0, q.size
      p = Sidekiq::Processor.new(@cap) do |pr, ex|
        result(pr, ex)
      end
      jid = JoeJob.perform_async(2)
      assert jid, jid
      assert_equal 1, q.size

      a = $count
      p.start
      sleep(0.05)
      p.terminate
      p.kill(true)

      b = $count
      assert_equal a, b
      assert_equal false, p.thread.status
      refute @latest_error, @latest_error.to_s
    end
  end
end
