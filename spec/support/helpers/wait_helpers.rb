# frozen_string_literal: true

module WaitHelpers
  extend self

  # Waits until the passed block returns true
  def wait_for(condition_name, max_wait_time: Capybara.default_max_wait_time, polling_interval: 0.01, reload: false)
    # Don't use `Time.now` because some tests use `:freeze_time`
    wait_until = ::Gitlab::Metrics::System.monotonic_time + max_wait_time
    loop do
      result = yield
      break result if result

      page.refresh if reload

      raise "Condition not met: #{condition_name}" if ::Gitlab::Metrics::System.monotonic_time > wait_until

      sleep(polling_interval)
    end
  end
end
