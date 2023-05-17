# frozen_string_literal: true

module Sidekiq
  class ReliableFetch < BaseReliableFetch
    # For reliable fetch we don't use Redis' blocking operations so
    # we inject a regular sleep into the loop.
    RELIABLE_FETCH_IDLE_TIMEOUT = 5 # seconds

    attr_reader :queues_size

    def initialize(options)
      super

      @queues = queues.uniq if strictly_ordered_queues
      @queues_size = queues.size
    end

    private

    def retrieve_unit_of_work
      queues_list = strictly_ordered_queues ? queues : queues.shuffle

      queues_list.each do |queue|
        work = Sidekiq.redis do |conn|
          conn.rpoplpush(queue, self.class.working_queue_name(queue))
        end

        return UnitOfWork.new(queue, work) if work
      end

      # We didn't find a job in any of the configured queues. Let's sleep a bit
      # to avoid uselessly burning too much CPU
      sleep(RELIABLE_FETCH_IDLE_TIMEOUT)

      nil
    end
  end
end
