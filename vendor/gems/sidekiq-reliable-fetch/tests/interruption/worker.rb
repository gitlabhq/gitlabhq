# frozen_string_literal: true

class RetryTestWorker
  include Sidekiq::Worker

  def perform(signal = 'KILL', wait_seconds = 1)
    Sidekiq.redis do |redis|
      redis.incr('times_has_been_run')
    end

    Process.kill(signal, Process.pid)

    sleep wait_seconds
  end
end
