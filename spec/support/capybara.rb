# rubocop:disable Style/GlobalVars
require 'capybara/rails'
require 'capybara/rspec'
require 'capybara-screenshot/rspec'
require 'selenium-webdriver'
require 'net/http'
require 'uri'

# Give CI some extra time
timeout = (ENV['CI'] || ENV['CI_SERVER']) ? 60 : 30

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
  options.add_argument("window-size=1240,1400")

  # Chrome won't work properly in a Docker container in sandbox mode
  options.add_argument("no-sandbox")

  # Run headless by default unless CHROME_HEADLESS specified
  unless ENV['CHROME_HEADLESS'] =~ /^(false|no|0)$/i
    options.add_argument("headless")

    # Chrome documentation says this flag is needed for now
    # https://developers.google.com/web/updates/2017/04/headless-chrome#cli
    options.add_argument("disable-gpu")
  end

  # Disable /dev/shm use in CI. See https://gitlab.com/gitlab-org/gitlab-ee/issues/4252
  options.add_argument("disable-dev-shm-usage") if ENV['CI'] || ENV['CI_SERVER']

  args = {}.merge( ENV['SELENIUM_REMOTE_URL'] ? { url: ENV['SELENIUM_REMOTE_URL'] } : {})

  Capybara::Selenium::Driver.new(
    app,
    browser: :chrome,
    desired_capabilities: capabilities,
    options: options,
    **args
  )
end

Capybara.javascript_driver = :chrome
Capybara.default_max_wait_time = timeout
Capybara.ignore_hidden_elements = true

# Keep only the screenshots generated from the last failing test suite
Capybara::Screenshot.prune_strategy = :keep_last_run
# From https://github.com/mattheworiordan/capybara-screenshot/issues/84#issuecomment-41219326
Capybara::Screenshot.register_driver(:chrome) do |driver, path|
  driver.browser.save_screenshot(path)
end

RSpec.configure do |config|
  config.before(:context, :js) do
    next if $capybara_server_already_started

    TestEnv.eager_load_driver_server
    $capybara_server_already_started = true
  end

  config.before(:example, :js) do
    session = Capybara.current_session

    allow(Gitlab::Application.routes).to receive(:default_url_options).and_return(
      host: session.server.host,
      port: session.server.port,
      protocol: 'http')

    # reset window size between tests
    unless session.current_window.size == [1240, 1400]
      session.current_window.resize_to(1240, 1400) rescue nil
    end


    puts Gitlab::Utils.to_boolean(ENV['GITLAB_SELENIUM_SERVER'])
    puts "====================================================="

    if Gitlab::Utils.to_boolean(ENV['GITLAB_SELENIUM_SERVER'])
      test_path = self.inspect.to_s.sub("(", "").sub(")>", "").split("\"")
      puts test_path
      puts "Hello World"

      uri =  URI::join("#{ENV['SELENIUM_REMOTE_URL']}/", "session/#{session.driver.browser.capabilities['webdriver.remote.sessionid']}/gitlab-meta")
      req = Net::HTTP::Post.new(uri, 'Content-Type' => 'application/json')
      req.body = {
        description: test_path[1],
        location: test_path[2],
      }.to_json

      puts uri;
      puts "====================================================="
   
      res = Net::HTTP.start(uri.hostname, uri.port) do |http|
        http.request(req)
      end

      case res
        when Net::HTTPSuccess, Net::HTTPRedirection
          puts res.inspect
          puts " Net::HTTPSuccess, Net::HTTPRedirection ====================================================="
        else
          puts res.inspect
          puts " else ====================================================="
      end
    end
  end

  config.after(:example, :js) do |example|
    # prevent localStorage from introducing side effects based on test order
    unless ['', 'about:blank', 'data:,'].include? Capybara.current_session.driver.browser.current_url
      execute_script("localStorage.clear();")
    end

    # capybara/rspec already calls Capybara.reset_sessions! in an `after` hook,
    # but `block_and_wait_for_requests_complete` is called before it so by
    # calling it explicitely here, we prevent any new requests from being fired
    # See https://github.com/teamcapybara/capybara/blob/ffb41cfad620de1961bb49b1562a9fa9b28c0903/lib/capybara/rspec.rb#L20-L25
    # We don't reset the session when the example failed, because we need capybara-screenshot to have access to it.
    Capybara.reset_sessions! unless example.exception
    block_and_wait_for_requests_complete
  end
end
