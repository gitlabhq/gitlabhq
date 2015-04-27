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
