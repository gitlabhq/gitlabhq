# frozen_string_literal: true

require_relative "helper"
require "sidekiq/scheduled"
require "sidekiq/api"

class ScheduledJob
  include Sidekiq::Job
  def perform(x)
  end
end

class MyStopper
  def call(worker_class, job, queue, r)
    yield if job["args"].first.odd?
  end
end

describe Sidekiq::Scheduled do
  describe "poller" do
    before do
      @config = reset!
      @error_1 = {"class" => ScheduledJob.name, "args" => [0], "queue" => "queue_1"}
      @error_2 = {"class" => ScheduledJob.name, "args" => [1], "queue" => "queue_2"}
      @error_3 = {"class" => ScheduledJob.name, "args" => [2], "queue" => "queue_3"}
      @future_1 = {"class" => ScheduledJob.name, "args" => [3], "queue" => "queue_4"}
      @future_2 = {"class" => ScheduledJob.name, "args" => [4], "queue" => "queue_5"}
      @future_3 = {"class" => ScheduledJob.name, "args" => [5], "queue" => "queue_6"}

      @retry = Sidekiq::RetrySet.new
      @scheduled = Sidekiq::ScheduledSet.new
      @poller = Sidekiq::Scheduled::Poller.new(@config)

      # @config.logger = ::Logger.new($stdout)
      # @config.logger.level = Logger::DEBUG
    end

    it "executes client middleware" do
      @config.client_middleware.add MyStopper

      @retry.schedule (Time.now - 60).to_f, @error_1
      @retry.schedule (Time.now - 60).to_f, @error_2
      @scheduled.schedule (Time.now - 60).to_f, @future_2
      @scheduled.schedule (Time.now - 60).to_f, @future_3

      @poller.enqueue

      assert_equal 0, Sidekiq::Queue.new("queue_1").size
      assert_equal 1, Sidekiq::Queue.new("queue_2").size
      assert_equal 0, Sidekiq::Queue.new("queue_5").size
      assert_equal 1, Sidekiq::Queue.new("queue_6").size
    end

    it "should empty the retry and scheduled queues up to the current time" do
      created_time = Time.new(2013, 2, 3)
      enqueued_time = Time.new(2013, 2, 4)

      Time.stub(:now, created_time) do
        @retry.schedule (enqueued_time - 60).to_f, @error_1.merge!("created_at" => created_time.to_f)
        @retry.schedule (enqueued_time - 50).to_f, @error_2.merge!("created_at" => created_time.to_f)
        @retry.schedule (enqueued_time + 60).to_f, @error_3.merge!("created_at" => created_time.to_f)
        @scheduled.schedule (enqueued_time - 60).to_f, @future_1.merge!("created_at" => created_time.to_f)
        @scheduled.schedule (enqueued_time - 50).to_f, @future_2.merge!("created_at" => created_time.to_f)
        @scheduled.schedule (enqueued_time + 60).to_f, @future_3.merge!("created_at" => created_time.to_f)
      end

      Time.stub(:now, enqueued_time) do
        @poller.enqueue

        @config.redis do |conn|
          %w[queue:queue_1 queue:queue_2 queue:queue_4 queue:queue_5].each do |queue_name|
            assert_equal 1, conn.llen(queue_name)
            job = Sidekiq.load_json(conn.lrange(queue_name, 0, -1)[0])
            assert_equal enqueued_time.to_f, job["enqueued_at"]
            assert_equal created_time.to_f, job["created_at"]
          end
        end

        assert_equal 1, @retry.size
        assert_equal 1, @scheduled.size
      end
    end

    it "should not enqueue jobs when terminate has been called" do
      created_time = Time.new(2013, 2, 3)
      enqueued_time = Time.new(2013, 2, 4)

      Time.stub(:now, created_time) do
        @retry.schedule (enqueued_time - 60).to_f, @error_1.merge!("created_at" => created_time.to_f)
        @scheduled.schedule (enqueued_time - 60).to_f, @future_1.merge!("created_at" => created_time.to_f)
      end

      Time.stub(:now, enqueued_time) do
        @poller.terminate
        @poller.enqueue

        @config.redis do |conn|
          %w[queue:queue_1 queue:queue_4].each do |queue_name|
            assert_equal 0, conn.llen(queue_name)
          end
        end

        assert_equal 1, @retry.size
        assert_equal 1, @scheduled.size
      end
    end

    def with_sidekiq_option(name, value)
      original, @config[name] = @config[name], value
      begin
        yield
      ensure
        @config[name] = original
      end
    end

    it "generates random intervals that target a configured average" do
      with_sidekiq_option(:poll_interval_average, 10) do
        i = 500
        intervals = Array.new(i) { @poller.send(:random_poll_interval) }

        assert intervals.all? { |x| x >= 5 }
        assert intervals.all? { |x| x <= 15 }
        assert_in_delta 10, intervals.sum.to_f / i, 0.5
      end
    end

    it "generates random intervals based on the number of known Sidekiq processes" do
      with_sidekiq_option(:average_scheduled_poll_interval, 10) do
        intervals_count = 500

        # Start with 10 processes
        10.times do |i|
          @config.redis do |conn|
            conn.sadd("processes", ["process-#{i}"])
          end
        end

        intervals = Array.new(intervals_count) { @poller.send(:random_poll_interval) }
        assert intervals.all? { |x| x.between?(0, 100) }

        # Reduce to 3 processes
        (3..9).each do |i|
          @config.redis do |conn|
            conn.srem("processes", ["process-#{i}"])
          end
        end

        intervals = Array.new(intervals_count) { @poller.send(:random_poll_interval) }
        assert intervals.all? { |x| x.between?(15, 45) }
      end
    end

    it "calculates an average poll interval based on a given number of processes" do
      with_sidekiq_option(:average_scheduled_poll_interval, 10) do
        assert_equal 30, @poller.send(:scaled_poll_interval, 3)
      end
    end
  end
end
