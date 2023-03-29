def assert(text, actual, expected)
  if actual == expected
    puts "#{text}: #{actual} (Success)"
  else
    puts "#{text}: #{actual} (Failed). Expected: #{expected}"
    exit 1
  end
end

def spawn_workers(number)
  pids = []

  number.times do
    pids << spawn('sidekiq -q default -q high -q low -r ./config.rb')
  end

  pids
end

# Stop Sidekiq workers
def stop_workers(pids)
  pids.each do |pid|
    Process.kill('KILL', pid)
    Process.wait pid
  end
end
