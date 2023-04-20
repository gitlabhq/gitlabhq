# frozen_string_literal: true

class ReliabilityTestWorker
  include Sidekiq::Worker

  def perform
    # To mimic long running job and to increase the probability of losing the job
    sleep 1

    Sidekiq.redis do |redis|
      redis.lpush(REDIS_FINISHED_LIST, jid)
    end
  end
end
