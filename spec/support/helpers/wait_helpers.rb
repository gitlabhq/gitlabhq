# frozen_string_literal: true

module WaitHelpers
  extend self

  # Waits until the passed block returns true
  def wait_for(condition_name, max_wait_time: Capybara.default_max_wait_time, polling_interval: 0.01, reload: false)
    wait_until = Time.now + max_wait_time.seconds
    loop do
      result = yield
      break result if result

      page.refresh if reload

      if Time.now > wait_until
        raise "Condition not met: #{condition_name}"
      else
        sleep(polling_interval)
      end
    end
  end
end
