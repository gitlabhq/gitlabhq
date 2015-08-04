module CapybaraHelpers
  # Execute a block a certain number of times before considering it a failure
  #
  # The given block is called, and if it raises a `Capybara::ExpectationNotMet`
  # error, we wait `interval` seconds and then try again, until `retries` is
  # met.
  #
  # This allows for better handling of timing-sensitive expectations in a
  # sketchy CI environment, for example.
  #
  # interval - Delay between retries in seconds (default: 0.5)
  # retries  - Number of times to execute before failing (default: 5)
  def allowing_for_delay(interval: 0.5, retries: 5)
    tries = 0

    begin
      sleep interval

      yield
    rescue Capybara::ExpectationNotMet => ex
      if tries <= retries
        tries += 1
        sleep interval
        retry
      else
        raise ex
      end
    end
  end
end

RSpec.configure do |config|
  config.include CapybaraHelpers, type: :feature
end
