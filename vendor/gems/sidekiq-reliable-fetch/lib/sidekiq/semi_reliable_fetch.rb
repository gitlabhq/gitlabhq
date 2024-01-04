# frozen_string_literal: true

module Sidekiq
  class SemiReliableFetch < BaseReliableFetch
    # We want the fetch operation to timeout every few seconds so the thread
    # can check if the process is shutting down. This constant is only used
    # for semi-reliable fetch.
    DEFAULT_SEMI_RELIABLE_FETCH_TIMEOUT = 5 # seconds

    def initialize(capsule)
      super

      @queues = @queues.uniq
    end

    private

    def retrieve_unit_of_work
      work = brpop_with_sidekiq
      return unless work

      queue, job = work
      unit_of_work = UnitOfWork.new(queue, job)

      Sidekiq.redis do |conn|
        conn.lpush(self.class.working_queue_name(unit_of_work.queue), unit_of_work.job)
      end

      unit_of_work
    end

    def brpop_with_sidekiq
      Sidekiq.redis do |conn|
        conn.blocking_call(
          conn.read_timeout + semi_reliable_fetch_timeout,
          "brpop",
          *queues_cmd,
          semi_reliable_fetch_timeout
        )
      end
    end

    def queues_cmd
      if strictly_ordered_queues
        @queues
      else
        @queues.shuffle
      end
    end

    def semi_reliable_fetch_timeout
      @semi_reliable_fetch_timeout ||= ENV['SIDEKIQ_SEMI_RELIABLE_FETCH_TIMEOUT']&.to_i || DEFAULT_SEMI_RELIABLE_FETCH_TIMEOUT
    end
  end
end
