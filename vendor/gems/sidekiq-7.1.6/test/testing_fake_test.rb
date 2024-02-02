# frozen_string_literal: true

require_relative "helper"
class PerformError < RuntimeError; end

class DirectJob
  include Sidekiq::Job
  def perform(a, b)
    a + b
  end
end

class EnqueuedJob
  include Sidekiq::Job
  def perform(a, b)
    a + b
  end
end

class StoredJob
  include Sidekiq::Job
  def perform(error)
    raise PerformError if error
  end
end

class SpecificJidJob
  include Sidekiq::Job
  sidekiq_class_attribute :count
  self.count = 0
  def perform(worker_jid)
    return unless worker_jid == jid
    self.class.count += 1
  end
end

class FirstJob
  include Sidekiq::Job
  sidekiq_class_attribute :count
  self.count = 0
  def perform
    self.class.count += 1
  end
end

class SecondJob
  include Sidekiq::Job
  sidekiq_class_attribute :count
  self.count = 0
  def perform
    self.class.count += 1
  end
end

class ThirdJob
  include Sidekiq::Job
  sidekiq_class_attribute :count
  def perform
    FirstJob.perform_async
    SecondJob.perform_async
  end
end

class QueueJob
  include Sidekiq::Job
  def perform(a, b)
    a + b
  end
end

class AltQueueJob
  include Sidekiq::Job
  sidekiq_options queue: :alt
  def perform(a, b)
    a + b
  end
end

describe "Sidekiq::Testing.fake" do
  before do
    reset!
    require "sidekiq/testing"
    Sidekiq::Testing.fake!
    EnqueuedJob.jobs.clear
    DirectJob.jobs.clear
  end

  after do
    Sidekiq::Testing.disable!
    Sidekiq::Queues.clear_all
  end

  it "stubs the async call" do
    assert_equal 0, DirectJob.jobs.size
    assert DirectJob.perform_async(1, 2)
    assert_in_delta Time.now.to_f, DirectJob.jobs.last["enqueued_at"], 0.1
    assert_equal 1, DirectJob.jobs.size
    assert DirectJob.perform_in(10, 1, 2)
    refute DirectJob.jobs.last["enqueued_at"]
    assert_equal 2, DirectJob.jobs.size
    assert DirectJob.perform_at(10, 1, 2)
    assert_equal 3, DirectJob.jobs.size
    soon = (Time.now.to_f + 10)
    assert_in_delta soon, DirectJob.jobs.last["at"], 0.1
  end

  it "stubs the enqueue call" do
    assert_equal 0, EnqueuedJob.jobs.size
    assert Sidekiq::Client.enqueue(EnqueuedJob, 1, 2)
    assert_equal 1, EnqueuedJob.jobs.size
  end

  it "stubs the enqueue_to call" do
    assert_equal 0, EnqueuedJob.jobs.size
    assert Sidekiq::Client.enqueue_to("someq", EnqueuedJob, 1, 2)
    assert_equal 1, Sidekiq::Queues["someq"].size
  end

  it "executes all stored jobs" do
    assert StoredJob.perform_async(false)
    assert StoredJob.perform_async(true)

    assert_equal 2, StoredJob.jobs.size
    assert_raises PerformError do
      StoredJob.drain
    end
    assert_equal 0, StoredJob.jobs.size
  end

  it "execute only jobs with assigned JID" do
    4.times do |i|
      jid = SpecificJidJob.perform_async(nil)
      SpecificJidJob.jobs[-1]["args"] = if i % 2 == 0
        ["wrong_jid"]
      else
        [jid]
      end
    end

    SpecificJidJob.perform_one
    assert_equal 0, SpecificJidJob.count

    SpecificJidJob.perform_one
    assert_equal 1, SpecificJidJob.count

    SpecificJidJob.drain
    assert_equal 2, SpecificJidJob.count
  end

  it "round trip serializes the job arguments" do
    assert_raises ArgumentError do
      StoredJob.perform_async(:mike)
    end

    Sidekiq.strict_args!(false)
    assert StoredJob.perform_async(:mike)
    job = StoredJob.jobs.first
    assert_equal "mike", job["args"].first
    StoredJob.clear
  ensure
    Sidekiq.strict_args!(:raise)
  end

  it "perform_one runs only one job" do
    DirectJob.perform_async(1, 2)
    DirectJob.perform_async(3, 4)
    assert_equal 2, DirectJob.jobs.size

    DirectJob.perform_one
    assert_equal 1, DirectJob.jobs.size

    DirectJob.clear
  end

  it "perform_one raise error upon empty queue" do
    DirectJob.clear
    assert_raises Sidekiq::EmptyQueueError do
      DirectJob.perform_one
    end
  end

  it "clears jobs across all workers" do
    Sidekiq::Job.jobs.clear
    FirstJob.count = 0
    SecondJob.count = 0

    assert_equal 0, FirstJob.jobs.size
    assert_equal 0, SecondJob.jobs.size

    FirstJob.perform_async
    SecondJob.perform_async

    assert_equal 1, FirstJob.jobs.size
    assert_equal 1, SecondJob.jobs.size

    Sidekiq::Job.clear_all

    assert_equal 0, FirstJob.jobs.size
    assert_equal 0, SecondJob.jobs.size

    assert_equal 0, FirstJob.count
    assert_equal 0, SecondJob.count
  end

  it "drains jobs across all workers" do
    Sidekiq::Job.jobs.clear
    FirstJob.count = 0
    SecondJob.count = 0

    assert_equal 0, FirstJob.jobs.size
    assert_equal 0, SecondJob.jobs.size

    assert_equal 0, FirstJob.count
    assert_equal 0, SecondJob.count

    FirstJob.perform_async
    SecondJob.perform_async

    assert_equal 1, FirstJob.jobs.size
    assert_equal 1, SecondJob.jobs.size

    Sidekiq::Job.drain_all

    assert_equal 0, FirstJob.jobs.size
    assert_equal 0, SecondJob.jobs.size

    assert_equal 1, FirstJob.count
    assert_equal 1, SecondJob.count
  end

  it "clears the jobs of workers having their queue name defined as a symbol" do
    assert_equal Symbol, AltQueueJob.sidekiq_options["queue"].class

    AltQueueJob.perform_async
    assert_equal 1, AltQueueJob.jobs.size
    assert_equal 1, Sidekiq::Queues[AltQueueJob.sidekiq_options["queue"].to_s].size

    AltQueueJob.clear
    assert_equal 0, AltQueueJob.jobs.size
    assert_equal 0, Sidekiq::Queues[AltQueueJob.sidekiq_options["queue"].to_s].size
  end

  it "drains jobs across all workers even when workers create new jobs" do
    Sidekiq::Job.jobs.clear
    FirstJob.count = 0
    SecondJob.count = 0

    assert_equal 0, ThirdJob.jobs.size

    assert_equal 0, FirstJob.count
    assert_equal 0, SecondJob.count

    ThirdJob.perform_async

    assert_equal 1, ThirdJob.jobs.size

    Sidekiq::Job.drain_all

    assert_equal 0, ThirdJob.jobs.size

    assert_equal 1, FirstJob.count
    assert_equal 1, SecondJob.count
  end

  it "drains jobs of workers with symbolized queue names" do
    Sidekiq::Job.jobs.clear

    AltQueueJob.perform_async(5, 6)
    assert_equal 1, AltQueueJob.jobs.size

    Sidekiq::Job.drain_all
    assert_equal 0, AltQueueJob.jobs.size
  end

  it "can execute a job" do
    DirectJob.execute_job(DirectJob.new, [2, 3])
  end

  describe "queue testing" do
    before do
      require "sidekiq/testing"
      Sidekiq::Testing.fake!
    end

    after do
      Sidekiq::Testing.disable!
      Sidekiq::Queues.clear_all
    end

    it "finds enqueued jobs" do
      assert_equal 0, Sidekiq::Queues["default"].size

      QueueJob.perform_async(1, 2)
      QueueJob.perform_async(1, 2)
      AltQueueJob.perform_async(1, 2)

      assert_equal 2, Sidekiq::Queues["default"].size
      assert_equal [1, 2], Sidekiq::Queues["default"].first["args"]

      assert_equal 1, Sidekiq::Queues["alt"].size
    end

    it "clears out all queues" do
      assert_equal 0, Sidekiq::Queues["default"].size

      QueueJob.perform_async(1, 2)
      QueueJob.perform_async(1, 2)
      AltQueueJob.perform_async(1, 2)

      Sidekiq::Queues.clear_all

      assert_equal 0, Sidekiq::Queues["default"].size
      assert_equal 0, QueueJob.jobs.size
      assert_equal 0, Sidekiq::Queues["alt"].size
      assert_equal 0, AltQueueJob.jobs.size
    end

    it "finds jobs enqueued by client" do
      Sidekiq::Client.push(
        "class" => "NonExistentJob",
        "queue" => "missing",
        "args" => [1]
      )

      assert_equal 1, Sidekiq::Queues["missing"].size
    end

    it "respects underlying array changes" do
      # Rspec expect change() syntax saves a reference to
      # an underlying array. When the array containing jobs is
      # derived, Rspec test using `change(QueueJob.jobs, :size).by(1)`
      # won't pass. This attempts to recreate that scenario
      # by saving a reference to the jobs array and ensuring
      # it changes properly on enqueueing
      jobs = QueueJob.jobs
      assert_equal 0, jobs.size
      QueueJob.perform_async(1, 2)
      assert_equal 1, jobs.size
    end
  end
end
