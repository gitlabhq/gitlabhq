require_relative "helper"
require "sidekiq/job_retry"
require "sidekiq/capsule"

class NewJob
  include Sidekiq::Job

  sidekiq_class_attribute :exhausted_called, :exhausted_job, :exhausted_exception

  sidekiq_retries_exhausted do |job, e|
    self.exhausted_called = true
    self.exhausted_job = job
    self.exhausted_exception = e
  end
end

class OldJob
  include Sidekiq::Job

  sidekiq_class_attribute :exhausted_called, :exhausted_job, :exhausted_exception

  sidekiq_retries_exhausted do |job|
    self.exhausted_called = true
    self.exhausted_job = job
  end
end

class DiscardJob
  include Sidekiq::Job

  sidekiq_class_attribute :exhausted_called

  sidekiq_retries_exhausted do |job, e|
    self.exhausted_called = true
    :discard
  end
end

class Foobar
  include Sidekiq::Job
end

class WrappedJob < ActiveJob::Base
  class_attribute :exhausted_called

  sidekiq_retries_exhausted do |job|
    WrappedJob.exhausted_called = true
  end
end

describe "sidekiq_retries_exhausted" do
  def cleanup
    [NewJob, OldJob].each do |worker_class|
      worker_class.exhausted_called = nil
      worker_class.exhausted_job = nil
      worker_class.exhausted_exception = nil
    end
    WrappedJob.exhausted_called = nil
  end

  before do
    @config = reset!
    cleanup
  end

  after do
    cleanup
  end

  def new_worker
    @new_worker ||= NewJob.new
  end

  def old_worker
    @old_worker ||= OldJob.new
  end

  def handler
    @handler ||= Sidekiq::JobRetry.new(@config.default_capsule)
  end

  def job(options = {})
    @job ||= Sidekiq.dump_json({"class" => "Bob", "args" => [1, 2, "foo"]}.merge(options))
  end

  it "does not run exhausted block when job successful on first run" do
    handler.local(new_worker, job("retry" => 2), "default") do
      # successful
    end

    refute NewJob.exhausted_called
  end

  it "does not run exhausted block when job successful on last retry" do
    handler.local(new_worker, job("retry_count" => 0, "retry" => 1), "default") do
      # successful
    end

    refute NewJob.exhausted_called
  end

  it "does not run exhausted block when retries not exhausted yet" do
    assert_raises RuntimeError do
      handler.local(new_worker, job("retry" => 1), "default") do
        raise "kerblammo!"
      end
    end

    refute NewJob.exhausted_called
  end

  it "runs exhausted block when retries exhausted" do
    assert_raises RuntimeError do
      handler.local(new_worker, job("retry_count" => 0, "retry" => 1), "default") do
        raise "kerblammo!"
      end
    end

    assert NewJob.exhausted_called
  end

  it "passes job and exception to retries exhausted block" do
    raised_error = assert_raises RuntimeError do
      handler.local(new_worker, job("retry_count" => 0, "retry" => 1), "default") do
        raise "kerblammo!"
      end
    end
    raised_error = raised_error.cause

    assert new_worker.exhausted_called
    assert_equal raised_error.message, new_worker.exhausted_job["error_message"]
    assert_equal raised_error, new_worker.exhausted_exception
  end

  it "passes job to retries exhausted block" do
    raised_error = assert_raises RuntimeError do
      handler.local(old_worker, job("retry_count" => 0, "retry" => 1), "default") do
        raise "kerblammo!"
      end
    end
    raised_error = raised_error.cause

    assert old_worker.exhausted_called
    assert_equal raised_error.message, old_worker.exhausted_job["error_message"]
    assert_nil new_worker.exhausted_exception
  end

  it "allows global failure handlers" do
    exhausted_job = nil
    exhausted_exception = nil
    @config.death_handlers.clear
    @config.death_handlers << proc do |job, ex|
      exhausted_job = job
      exhausted_exception = ex
    end
    f = Foobar.new
    raised_error = assert_raises RuntimeError do
      handler.local(f, job("retry_count" => 0, "retry" => 1), "default") do
        raise "kerblammo!"
      end
    end
    raised_error = raised_error.cause

    assert exhausted_job
    assert_equal raised_error, exhausted_exception
  end

  it "adds jobs to the dead set" do
    assert_raises RuntimeError do
      handler.local(new_worker, job("retry" => 0), "default") do
        raise "kerblammo!"
      end
    end

    assert_equal 1, Sidekiq::DeadSet.new.size
  end

  it "allows disabling dead set" do
    assert_raises RuntimeError do
      handler.local(new_worker, job("retry" => 0, "dead" => false), "default") do
        raise "kerblammo!"
      end
    end

    assert_equal 0, Sidekiq::DeadSet.new.size
  end

  it "does not allow disabling global failure handlers when disabling dead set" do
    exhausted_job = nil
    exhausted_exception = nil
    @config.death_handlers.clear
    @config.death_handlers << proc do |job, ex|
      exhausted_job = job
      exhausted_exception = ex
    end
    assert_raises RuntimeError do
      handler.local(new_worker, job("retry" => 0, "dead" => false), "default") do
        raise "kerblammo!"
      end
    end

    assert exhausted_job
    assert exhausted_exception
  end

  it "supports discard option to disable global failure handlers and dead set" do
    discard_job = DiscardJob.new

    exhausted_job = nil
    exhausted_exception = nil
    @config.death_handlers.clear
    @config.death_handlers << proc do |job, ex|
      exhausted_job = job
      exhausted_exception = ex
    end
    assert_raises RuntimeError do
      handler.local(discard_job, job("retry" => 0), "default") do
        raise "kerblammo!"
      end
    end

    assert DiscardJob.exhausted_called
    assert_equal 0, Sidekiq::DeadSet.new.size
    assert_nil exhausted_job
    assert_nil exhausted_exception
  end

  it "supports wrapped jobs" do
    assert_raises RuntimeError do
      handler.local(WrappedJob.new, job("retry_count" => 0, "retry" => 1, "wrapped" => WrappedJob.to_s), "default") do
        raise "kerblammo!"
      end
    end

    assert WrappedJob.exhausted_called
  end
end
