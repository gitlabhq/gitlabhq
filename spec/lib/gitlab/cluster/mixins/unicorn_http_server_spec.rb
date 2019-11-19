# frozen_string_literal: true

require 'spec_helper'

# For easier debugging set `UNICORN_DEBUG=1`

describe Gitlab::Cluster::Mixins::UnicornHttpServer do
  UNICORN_STARTUP_TIMEOUT = 30

  context 'when running Unicorn' do
    using RSpec::Parameterized::TableSyntax

    where(:signal, :exitstatus, :termsig) do
      # executes phased restart block
      :USR2 | 140 | nil
      :QUIT | 140 | nil

      # does not execute phased restart block
      :INT | 0 | nil
      :TERM | 0 | nil
    end

    with_them do
      it 'properly handles process lifecycle' do
        with_unicorn(workers: 1) do |pid|
          Process.kill(signal, pid)

          child_pid, child_status = Process.wait2(pid)
          expect(child_pid).to eq(pid)
          expect(child_status.exitstatus).to eq(exitstatus)
          expect(child_status.termsig).to eq(termsig)
        end
      end
    end
  end

  private

  def with_unicorn(workers:, timeout: UNICORN_STARTUP_TIMEOUT)
    with_unicorn_configs(workers: workers) do |unicorn_rb, config_ru|
      cmdline = [
        "bundle", "exec", "unicorn",
        "-I", Rails.root.to_s,
        "-c", unicorn_rb,
        config_ru
      ]

      IO.popen(cmdline) do |process|
        # wait for process to start:
        # I, [2019-10-15T13:21:27.565225 #3089]  INFO -- : master process ready
        wait_for_output(process, /master process ready/, timeout: timeout)
        consume_output(process)

        yield(process.pid)
      ensure
        begin
          Process.kill(:KILL, process.pid)
        rescue Errno::ESRCH
        end
      end
    end
  end

  def with_unicorn_configs(workers:)
    Dir.mktmpdir do |dir|
      File.write "#{dir}/unicorn.rb", <<-EOF
        require './lib/gitlab/cluster/lifecycle_events'
        require './lib/gitlab/cluster/mixins/unicorn_http_server'

        worker_processes #{workers}
        listen "127.0.0.1:0"
        preload_app true

        Unicorn::HttpServer.prepend(#{described_class})

        mutex = Mutex.new

        Gitlab::Cluster::LifecycleEvents.on_before_blackout_period do
          mutex.synchronize do
            exit(140)
          end
        end

        # redirect stderr to stdout
        $stderr.reopen($stdout)
      EOF

      File.write "#{dir}/config.ru", <<-EOF
        run -> (env) { [404, {}, ['']] }
      EOF

      yield("#{dir}/unicorn.rb", "#{dir}/config.ru")
    end
  end

  def wait_for_output(process, output, timeout:)
    Timeout.timeout(timeout) do
      loop do
        line = process.readline
        puts "UNICORN_DEBUG: #{line}" if ENV['UNICORN_DEBUG']
        break if line =~ output
      end
    end
  end

  def consume_output(process)
    Thread.new do
      loop do
        line = process.readline
        puts "UNICORN_DEBUG: #{line}" if ENV['UNICORN_DEBUG']
      end
    rescue
    end
  end
end
