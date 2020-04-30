# frozen_string_literal: true

module ConcurrentHelpers
  Cancelled = Class.new(StandardError)

  # To test for contention, we may need to run some actions in parallel. This
  # helper takes an array of blocks and schedules them all on different threads
  # in a fixed-size thread pool.
  #
  # @param [Array[Proc]] blocks
  # @param [Integer] task_wait_time: time to wait for each task (upper bound on
  #                                  reasonable task execution time)
  # @param [Integer] max_concurrency: maximum number of tasks to run at once
  #
  def run_parallel(blocks, task_wait_time: 20.seconds, max_concurrency: Concurrent.processor_count - 1)
    thread_pool = Concurrent::FixedThreadPool.new(
      [2, max_concurrency].max, { max_queue: blocks.size }
    )
    opts = { executor: thread_pool }

    error = Concurrent::MVar.new

    blocks.map { |block| Concurrent::Future.execute(opts, &block) }.each do |future|
      future.wait(task_wait_time)

      if future.complete?
        error.put(future.reason) if future.reason && error.empty?
      else
        future.cancel
        error.put(Cancelled.new) if error.empty?
      end
    end

    raise error.take if error.full?
  ensure
    thread_pool.shutdown
    thread_pool.wait_for_termination(10)
    thread_pool.kill if thread_pool.running?
  end
end
