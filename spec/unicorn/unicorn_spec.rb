require 'fileutils'

require 'excon'

require 'spec_helper'

describe 'Unicorn' do
  before(:all) do
    config_lines = File.read('config/unicorn.rb.example').split("\n")

    # Remove these because they make setup harder.
    config_lines = config_lines.reject do |line|
      %w[
        working_directory
        worker_processes
        listen
        pid
        stderr_path
        stdout_path
      ].any? { |prefix| line.start_with?(prefix) }
    end

    config_lines << "working_directory '#{Rails.root}'"

    # We want to have exactly 1 worker process because that makes it
    # predictable which process will handle our requests.
    config_lines << 'worker_processes 1'

    @socket_path = File.join(Dir.pwd, 'tmp/tests/unicorn.socket')
    config_lines << "listen '#{@socket_path}'"

    ready_file = 'tmp/tests/unicorn-worker-ready'
    FileUtils.rm_f(ready_file)
    after_fork_index = config_lines.index { |l| l.start_with?('after_fork') }
    config_lines.insert(after_fork_index + 1, "File.write('#{ready_file}', Process.pid)")

    config_path = 'tmp/tests/unicorn.rb'
    File.write(config_path, config_lines.join("\n") + "\n")

    rackup_path = 'tmp/tests/config.ru'
    File.write(rackup_path, <<~EOS)
      app =
        proc do |env|
          if env['REQUEST_METHOD'] == 'GET'
            [200, {}, [Process.pid]]
          else
            Process.kill(env['QUERY_STRING'], Process.pid)
            [200, {}, ['Bye!']]
          end
        end

      run app
    EOS

    cmd = %W[unicorn -E test -c #{config_path} #{rackup_path}]
    @unicorn_master_pid = spawn(*cmd)
    wait_unicorn_boot!(@unicorn_master_pid, ready_file)
    WebMock.allow_net_connect!
  end

  %w[SIGQUIT SIGTERM SIGKILL].each do |signal|
    it "has a worker that self-terminates on signal #{signal}" do
      response = Excon.get('unix://', socket: @socket_path)
      expect(response.status).to eq(200)

      worker_pid = response.body.to_i
      expect(worker_pid).to be > 0

      begin
        Excon.post("unix://?#{signal}", socket: @socket_path)
      rescue Excon::Error::Socket
        # The connection may be closed abruptly
      end

      expect(pid_gone?(worker_pid)).to eq(true)
    end
  end

  after(:all) do
    WebMock.disable_net_connect!(allow_localhost: true)
    Process.kill('TERM', @unicorn_master_pid)
  end

  def wait_unicorn_boot!(master_pid, ready_file)
    # We have seen the boot timeout after 2 minutes in CI so let's set it to 5 minutes.
    timeout = 5 * 60
    timeout.times do
      return if File.exist?(ready_file)

      pid = Process.waitpid(master_pid, Process::WNOHANG)
      raise "unicorn failed to boot: #{$?}" unless pid.nil?

      sleep 1
    end

    raise "unicorn boot timed out after #{timeout} seconds"
  end

  def pid_gone?(pid)
    # Worker termination should take less than a second. That makes 10
    # seconds a generous timeout.
    10.times do
      begin
        Process.kill(0, pid)
      rescue Errno::ESRCH
        return true
      end

      sleep 1
    end

    false
  end
end
