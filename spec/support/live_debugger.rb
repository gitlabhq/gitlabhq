require 'io/console'

module LiveDebugger
  def live_debug
    `open #{current_url}`

    puts "\nCurrent example is paused for live debugging"
    puts "The current user credentials are: #{@current_user.username} / 12345678" if @current_user
    puts "Press 'c' to continue the execution of the example"

    loop do
      if $stdin.getch == 'c'
        break
      else
        puts "Please press 'c' to continue the execution of the example! ;)"
      end
    end

    puts "Back to the example!"
  end
end
