require 'capybara/rails'
require 'capybara/rspec'
require 'capybara/poltergeist'

# Give CI some extra time
timeout = (ENV['CI'] || ENV['CI_SERVER']) ? 90 : 10

Capybara.javascript_driver = :poltergeist
Capybara.register_driver :poltergeist do |app|
  Capybara::Poltergeist::Driver.new(app, js_errors: true, timeout: timeout, window_size: [1366, 768])
end

Capybara.default_wait_time = timeout
Capybara.ignore_hidden_elements = true

unless ENV['CI'] || ENV['CI_SERVER']
  require 'capybara-screenshot/rspec'

  # Keep only the screenshots generated from the last failing test suite
  Capybara::Screenshot.prune_strategy = :keep_last_run
end

RSpec.configure do |config|
  config.before(:suite) do
    TestEnv.warm_asset_cache
  end
end
