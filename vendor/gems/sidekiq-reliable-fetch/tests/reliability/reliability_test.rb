# frozen_string_literal: true

require 'sidekiq'
require 'sidekiq/cli'
require_relative 'config'

def spawn_workers_and_stop_them_on_a_half_way
  pids = spawn_workers

  wait_until do |queue_size|
    queue_size < NUMBER_OF_JOBS / 2
  end

  first_half_pids, second_half_pids = split_array(pids)

  puts 'Killing half of the workers...'
  signal_to_workers('KILL', first_half_pids)

  puts 'Stopping another half of the workers...'
  signal_to_workers('TERM', second_half_pids)
end

def spawn_workers_and_let_them_finish
  puts 'Spawn workers and let them finish...'

  pids = spawn_workers

  wait_until do |queue_size|
    queue_size.zero?
  end

  if %i[semi reliable].include? JOB_FETCHER
    puts 'Waiting for clean up process that will requeue dead jobs...'
    sleep WAIT_CLEANUP
  end

  signal_to_workers('TERM', pids)
end

def wait_until
  loop do
    sleep 3

    queue_size = current_queue_size
    puts "Jobs in the queue:#{queue_size}"

    break if yield(queue_size)
  end
end

def signal_to_workers(signal, pids)
  pids.each { |pid| Process.kill(signal, pid) }
  pids.each { |pid| Process.wait(pid) }
end

def spawn_workers
  pids = []
  NUMBER_OF_WORKERS.times do
    pids << spawn('sidekiq -q default -q low -q high -r ./config.rb')
  end

  pids
end

def current_queue_size
  Sidekiq.redis { |c| c.llen('queue:default') }
end

def duplicates
  Sidekiq.redis { |c| c.llen(REDIS_FINISHED_LIST) }
end

# Splits array into two halves
def split_array(arr)
  first_arr = arr.take(arr.size / 2)
  second_arr = arr - first_arr
  [first_arr, second_arr]
end

##########################################################

puts '########################################'
puts "Mode: #{JOB_FETCHER}"
puts '########################################'

Sidekiq.redis(&:flushdb)

jobs = []

NUMBER_OF_JOBS.times do
  jobs << ReliabilityTestWorker.perform_async
end

puts "Queued #{NUMBER_OF_JOBS} jobs"

spawn_workers_and_stop_them_on_a_half_way
spawn_workers_and_let_them_finish

jobs_lost = 0

Sidekiq.redis do |redis|
  jobs.each do |job|
    next if redis.lrem(REDIS_FINISHED_LIST, 1, job) == 1
    jobs_lost += 1
  end
end

puts "Remaining unprocessed: #{jobs_lost}. Max allowed: #{NUMBER_OF_JOBS_LOST_ALLOWED}"
puts "Duplicates found: #{duplicates}. Max allowed: #{NUMBER_OF_DUPLICATE_JOBS_ALLOWED}"

if jobs_lost <= NUMBER_OF_JOBS_LOST_ALLOWED && duplicates <= NUMBER_OF_DUPLICATE_JOBS_ALLOWED
  exit 0
else
  exit 1
end
