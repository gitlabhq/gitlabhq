# frozen_string_literal: true

require_relative "helper"
require "sidekiq/manager"

describe Sidekiq::Manager do
  before do
    @config = reset!
    @cap = @config.default_capsule
  end

  def new_manager
    Sidekiq::Manager.new(@cap)
  end

  it "creates N processor instances" do
    mgr = new_manager
    assert_equal @cap.concurrency, mgr.workers.size
  end

  it "shuts down the system" do
    mgr = new_manager
    mgr.start
    mgr.stop(::Process.clock_gettime(::Process::CLOCK_MONOTONIC))
  end

  it "throws away dead processors" do
    mgr = new_manager
    init_size = mgr.workers.size
    processor = mgr.workers.first
    mgr.quiet
    mgr.processor_result(processor, "ignored")

    assert_equal init_size - 1, mgr.workers.size
    refute mgr.workers.include?(processor)
  end
end
