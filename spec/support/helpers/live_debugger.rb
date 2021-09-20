# frozen_string_literal: true

require 'io/console'

module LiveDebugger
  def live_debug
    puts
    puts "Current example is paused for live debugging."

    if is_headless_disabled?
      puts "Switch to the browser window that was automatically opened to run the test in order to view current page"
    else
      puts "Opening #{current_url} in your default browser..."
    end

    puts "The current user credentials are: #{@current_user.username} / #{@current_user.password}" if @current_user
    puts "Press any key to resume the execution of the example!!"

    `open #{current_url}` unless is_headless_disabled?

    loop until $stdin.getch

    puts "Back to the example!"
  end

  def is_headless_disabled?
    ActiveSupport::Deprecation.warn("CHROME_HEADLESS is deprecated. Use WEBDRIVER_HEADLESS instead.") if ENV.key?('CHROME_HEADLESS')

    ENV['WEBDRIVER_HEADLESS'] =~ /^(false|no|0)$/i || ENV['CHROME_HEADLESS'] =~ /^(false|no|0)$/i
  end
end
