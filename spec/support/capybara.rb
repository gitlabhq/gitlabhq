# rubocop:disable Style/GlobalVars
require 'capybara/rails'
require 'capybara/rspec'
require 'capybara/poltergeist'
require 'capybara-screenshot/rspec'

# Give CI some extra time
timeout = (ENV['CI'] || ENV['CI_SERVER']) ? 60 : 30

Capybara.javascript_driver = :poltergeist
Capybara.register_driver :poltergeist do |app|
  Capybara::Poltergeist::Driver.new(
    app,
    js_errors: true,
    timeout: timeout,
    window_size: [1366, 768],
    url_whitelist: %w[localhost 127.0.0.1],
    url_blacklist: %w[.mp4 .png .gif .avi .bmp .jpg .jpeg],
    phantomjs_options: [
      '--load-images=yes'
    ]
  )
end

Capybara.default_max_wait_time = timeout
Capybara.ignore_hidden_elements = true

# Keep only the screenshots generated from the last failing test suite
Capybara::Screenshot.prune_strategy = :keep_last_run

RSpec.configure do |config|
  config.before(:context, :js) do
    next if $capybara_server_already_started

    TestEnv.eager_load_driver_server
    $capybara_server_already_started = true
  end
end
