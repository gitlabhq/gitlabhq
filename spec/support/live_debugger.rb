require 'io/console'

module LiveDebugger
  def live_debug
    puts "\nCurrent example is paused for live debugging."
    puts "Opening #{current_url} in your default browser..."
    puts "The current user credentials are: #{@current_user.username} / 12345678" if @current_user
    puts "Press '^C' to continue the execution of the example"

    `open #{current_url}`

    catch :unpause_test do
      trap('INT') { throw :unpause_test }
      loop do
        sleep(1)
      end
    end

    # If the command is 'DEFAULT', the Ruby's default handler will be invoked.
    # http://docs.rubydocs.org/rails-4-2-8-ruby-2-3-4/Ruby%202.3.4/classes/Kernel.html#method-i-trap
    trap('INT') { 'DEFAULT' }

    puts "Back to the example!"
  end
end
