require 'capybara/rails'
require 'capybara/rspec'
require 'capybara/poltergeist'

# Give CI some extra time
timeout = (ENV['CI'] || ENV['CI_SERVER']) ? 90 : 10

Capybara.javascript_driver = :poltergeist
Capybara.register_driver :poltergeist do |app|
  Capybara::Poltergeist::Driver.new(app, js_errors: true, timeout: timeout)
end

Capybara.default_wait_time = timeout
Capybara.ignore_hidden_elements = true

unless ENV['CI'] || ENV['CI_SERVER']
  require 'capybara-screenshot/rspec'

  # Keep only the screenshots generated from the last failing test suite
  Capybara::Screenshot.prune_strategy = :keep_last_run
end

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
