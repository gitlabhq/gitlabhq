# frozen_string_literal: true

require "google/cloud/profiler/v2"
require "logger"

module CloudProfilerAgent
  # Looper is responsible for the main loop of the agent. It calls a
  # block repeatedly, handling errors, backing off, and retrying as
  # appropriate.

  class Looper
    LOG_MESSAGE = "Google Cloud Profiler Ruby"

    def initialize(
      min_iteration_sec: 10,
      max_iteration_sec: 60 * 60,
      backoff_factor: 1.5,
      sleeper: ->(sec) { sleep(sec) },
      clock: -> { Process.clock_gettime(Process::CLOCK_MONOTONIC) },
      rander: -> { rand },
      logger: nil,
      log_labels: {}
    )

      # the minimum and maximum time between iterations of the profiler loop,
      # in seconds. Normally the Cloud Profiler API tells us how fast to go,
      # but we back off in case of error.
      @min_iteration_sec = min_iteration_sec
      @max_iteration_sec = max_iteration_sec
      @backoff_factor = backoff_factor

      # stubbable for testing
      @sleeper = sleeper
      @clock = clock
      @rander = rander

      @logger = logger || ::Logger.new($stdout)
      @log_labels = log_labels
    end

    attr_reader :min_iteration_sec, :max_iteration_sec, :backoff_factor, :logger, :log_labels

    def run(max_iterations = 0)
      iterations = 0
      iteration_time = @min_iteration_sec
      loop do
        start_time = @clock.call
        iterations += 1
        begin
          yield
        rescue ::Google::Cloud::Error => e
          logger.error(
            gcp_ruby_status: "error",
            error: e.inspect,
            **log_labels
          )

          backoff = backoff_duration(e)
          if backoff.nil?
            iteration_time = @max_iteration_sec
          else
            # This might be longer than max_iteration_sec and that's OK: with
            # a very large number of agents it might be necessary to achieve
            # the objective of 1 profile per minute.
            @sleeper.call(backoff)
            iteration_time = @min_iteration_sec
          end
        rescue StandardError => e
          iteration_time *= @backoff_factor + (@rander.call / 2)
          elapsed = @clock.call - start_time
          logger.error(
            gcp_ruby_status: "error",
            error: e.inspect,
            duration_s: elapsed,
            **log_labels
          )
        rescue Exception => e # rubocop:disable Lint/RescueException
          # We rescue exception here to make sure we log the error message, then we re-raise the exception.
          logger.error(
            gcp_ruby_status: "exception",
            error: e.inspect,
            **log_labels
          )
          raise e
        else
          iteration_time = @min_iteration_sec
        end

        return unless iterations < max_iterations || max_iterations == 0

        iteration_time = [@max_iteration_sec, iteration_time].min
        next_time = start_time + iteration_time
        delay = next_time - @clock.call
        @sleeper.call(delay) if delay > 0
      end
    end

    private

    def backoff_duration(error)
      # It's unclear how this should work, so this is based on a guess.
      #
      # https://github.com/googleapis/google-api-ruby-client/issues/1498
      match = /backoff for (?:(\d+)h)?(?:(\d+)m)?(?:(\d+)s)?/.match(error.message)
      return if match.nil?

      hours = Integer(match[1] || 0)
      minutes = Integer(match[2] || 0)
      seconds = Integer(match[3] || 0)

      seconds + (minutes * 60) + (hours * 60 * 60)
    end
  end
end
