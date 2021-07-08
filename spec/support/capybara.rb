# frozen_string_literal: true

# rubocop:disable Style/GlobalVars
require 'capybara/rails'
require 'capybara/rspec'
require 'capybara-screenshot/rspec'
require 'selenium-webdriver'

# Give CI some extra time
timeout = ENV['CI'] || ENV['CI_SERVER'] ? 60 : 30

# Support running Capybara on a specific port to allow saving commonly used pages
Capybara.server_port = ENV['CAPYBARA_PORT'] if ENV['CAPYBARA_PORT']

# Define an error class for JS console messages
JSConsoleError = Class.new(StandardError)

# Filter out innocuous JS console messages
JS_CONSOLE_FILTER = Regexp.union([
  '"[HMR] Waiting for update signal from WDS..."',
  '"[WDS] Hot Module Replacement enabled."',
  '"[WDS] Live Reloading enabled."',
  'Download the Vue Devtools extension',
  'Download the Apollo DevTools',
  "Unrecognized feature: 'interest-cohort'"
])

CAPYBARA_WINDOW_SIZE = [1366, 768].freeze

# Run Workhorse on the given host and port, proxying to Puma on a UNIX socket,
# for a closer-to-production experience
Capybara.register_server :puma_via_workhorse do |app, port, host, **options|
  file = Tempfile.new
  socket_path = file.path
  file.close! # We just want the filename

  TestEnv.with_workhorse(host, port, socket_path) do
    Capybara.servers[:puma].call(app, nil, socket_path, **options)
  end
end

Capybara.register_driver :chrome do |app|
  capabilities = Selenium::WebDriver::Remote::Capabilities.chrome(
    # This enables access to logs with `page.driver.manage.get_log(:browser)`
    loggingPrefs: {
      browser: "ALL",
      client: "ALL",
      driver: "ALL",
      server: "ALL"
    }
  )

  options = Selenium::WebDriver::Chrome::Options.new

  # Force the browser's scale factor to prevent inconsistencies on high-res devices
  options.add_argument('--force-device-scale-factor=1')

  options.add_argument("window-size=#{CAPYBARA_WINDOW_SIZE.join(',')}")

  # Chrome won't work properly in a Docker container in sandbox mode
  options.add_argument("no-sandbox")

  # Run headless by default unless WEBDRIVER_HEADLESS specified
  options.add_argument("headless") unless ENV['WEBDRIVER_HEADLESS'] =~ /^(false|no|0)$/i || ENV['CHROME_HEADLESS'] =~ /^(false|no|0)$/i

  # Disable /dev/shm use in CI. See https://gitlab.com/gitlab-org/gitlab/issues/4252
  options.add_argument("disable-dev-shm-usage") if ENV['CI'] || ENV['CI_SERVER']

  # Explicitly set user-data-dir to prevent crashes. See https://gitlab.com/gitlab-org/gitlab-foss/issues/58882#note_179811508
  options.add_argument("user-data-dir=/tmp/chrome") if ENV['CI'] || ENV['CI_SERVER']

  # Chrome 75 defaults to W3C mode which doesn't allow console log access
  options.add_option(:w3c, false)

  Capybara::Selenium::Driver.new(
    app,
    browser: :chrome,
    desired_capabilities: capabilities,
    options: options
  )
end

Capybara.register_driver :firefox do |app|
  capabilities = Selenium::WebDriver::Remote::Capabilities.firefox(
    log: {
      level: :trace
    }
  )

  options = Selenium::WebDriver::Firefox::Options.new(log_level: :trace)

  options.add_argument("--window-size=#{CAPYBARA_WINDOW_SIZE.join(',')}")

  # Run headless by default unless WEBDRIVER_HEADLESS specified
  options.add_argument("--headless") unless ENV['WEBDRIVER_HEADLESS'] =~ /^(false|no|0)$/i

  Capybara::Selenium::Driver.new(
    app,
    browser: :firefox,
    desired_capabilities: capabilities,
    options: options
  )
end

Capybara.server = :puma_via_workhorse
Capybara.javascript_driver = ENV.fetch('WEBDRIVER', :chrome).to_sym
Capybara.default_max_wait_time = timeout
Capybara.ignore_hidden_elements = true
Capybara.default_normalize_ws = true
Capybara.enable_aria_label = true

Capybara::Screenshot.append_timestamp = false

Capybara::Screenshot.register_filename_prefix_formatter(:rspec) do |example|
  example.full_description.downcase.parameterize(separator: "_")[0..99]
end
# Keep only the screenshots generated from the last failing test suite
Capybara::Screenshot.prune_strategy = :keep_last_run
# From https://github.com/mattheworiordan/capybara-screenshot/issues/84#issuecomment-41219326
Capybara::Screenshot.register_driver(:chrome) do |driver, path|
  driver.browser.save_screenshot(path)
end

RSpec.configure do |config|
  config.include CapybaraHelpers, type: :feature

  config.before(:context, :js) do
    # This prevents Selenium from creating thousands of connections while waiting for
    # an element to appear
    webmock_enable_with_http_connect_on_start!

    next if $capybara_server_already_started

    TestEnv.eager_load_driver_server
    $capybara_server_already_started = true
  end

  config.after(:context, :js) do
    # WebMock doesn't stub connections, so we need to restore the original behavior
    # to prevent many specs from failing:
    # https://github.com/bblimke/webmock/blob/master/README.md#connecting-on-nethttpstart
    webmock_enable!
  end

  config.before(:example, :js) do
    session = Capybara.current_session

    allow(Gitlab::Application.routes).to receive(:default_url_options).and_return(
      host: session.server.host,
      port: session.server.port,
      protocol: 'http')

    # CSRF protection is disabled by default. We only enable this for JS specs because some forms
    # require Javascript to set the CSRF token.
    allow_any_instance_of(ActionController::Base).to receive(:protect_against_forgery?).and_return(true)

    # reset window size between tests
    unless session.current_window.size == CAPYBARA_WINDOW_SIZE
      begin
        session.current_window.resize_to(*CAPYBARA_WINDOW_SIZE)
      rescue StandardError # ?
      end
    end
  end

  # The :capybara_ignore_server_errors metadata means unhandled exceptions raised
  # by the application under test will not necessarily fail the server. This is
  # useful when testing conditions that are expected to raise a 500 error in
  # production; it should not be used on the happy path.
  config.around(:each, :capybara_ignore_server_errors) do |example|
    Capybara.raise_server_errors = false

    example.run
  ensure
    Capybara.raise_server_errors = true
  end

  config.append_after do |example|
    if example.metadata[:screenshot]
      screenshot = example.metadata[:screenshot][:image] || example.metadata[:screenshot][:html]
      screenshot&.delete_prefix!(ENV.fetch('CI_PROJECT_DIR', ''))
      example.metadata[:stdout] = %{[[ATTACHMENT|#{screenshot}]]}
    end
  end

  config.after(:example, :js) do |example|
    # when a test fails, display any messages in the browser's console
    # but fail don't add the message if the failure is a pending test that got
    # fixed. If we raised the `JSException` the fixed test would be marked as
    # failed again.
    if example.exception && !example.exception.is_a?(RSpec::Core::Pending::PendingExampleFixedError)
      begin
        console = page.driver.browser.manage.logs.get(:browser)&.reject { |log| log.message =~ JS_CONSOLE_FILTER }

        if console.present?
          message = "Unexpected browser console output:\n" + console.map(&:message).join("\n")
          raise JSConsoleError, message
        end
      rescue Selenium::WebDriver::Error::WebDriverError => error
        if error.message =~ %r{unknown command: session/[0-9a-zA-Z]+(?:/se)?/log}
          message = "Unable to access Chrome javascript console logs. You may be using an outdated version of ChromeDriver."
          raise JSConsoleError, message
        else
          raise error
        end
      end
    end

    # prevent localStorage from introducing side effects based on test order
    unless ['', 'about:blank', 'data:,'].include? Capybara.current_session.driver.browser.current_url
      execute_script("localStorage.clear();")
    end

    # capybara/rspec already calls Capybara.reset_sessions! in an `after` hook,
    # but `block_and_wait_for_requests_complete` is called before it so by
    # calling it explicitly here, we prevent any new requests from being fired
    # See https://github.com/teamcapybara/capybara/blob/ffb41cfad620de1961bb49b1562a9fa9b28c0903/lib/capybara/rspec.rb#L20-L25
    # We don't reset the session when the example failed, because we need capybara-screenshot to have access to it.
    Capybara.reset_sessions! unless example.exception
    block_and_wait_for_requests_complete
  end
end
