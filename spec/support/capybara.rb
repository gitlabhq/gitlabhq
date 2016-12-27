require 'capybara/rails'
require 'capybara/rspec'
require 'capybara/poltergeist'

# Give CI some extra time
timeout = (ENV['CI'] || ENV['CI_SERVER']) ? 90 : 10

browser = ENV['BROWSER'].to_sym if /^(firefox|chrome|internet_explorer|safari)$/.match(ENV['BROWSER'])
driver = browser ? :selenium : :poltergeist

Capybara.javascript_driver = driver
Capybara.register_driver driver do |app|
  if driver == :selenium
    Capybara::Selenium::Driver.new(
      app,
      browser: browser,
      desired_capabilities: Selenium::WebDriver::Remote::Capabilities.send(browser)
    )
  else
    Capybara::Poltergeist::Driver.new(
      js_errors: true,
      timeout: timeout,
      window_size: [1366, 768],
      phantomjs_options: [
        '--load-images=no'
      ]
    )
  end
end

Capybara.default_max_wait_time = timeout
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
