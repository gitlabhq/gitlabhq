# frozen_string_literal: true

require 'io/console'

module LiveDebugger
  def live_debug
    puts
    puts "Current example is paused for live debugging."

    if ENV['CHROME_HEADLESS'] =~ /^(false|no|0)$/i
      puts "Switch to the Chrome window that was automatically opened to run the test in order to view current page"
    else
      puts "Opening #{current_url} in your default browser..."
    end

    puts "The current user credentials are: #{@current_user.username} / #{@current_user.password}" if @current_user
    puts "Press any key to resume the execution of the example!!"

    `open #{current_url}` if ENV['CHROME_HEADLESS'] !~ /^(false|no|0)$/i

    loop until $stdin.getch

    puts "Back to the example!"
  end
end
