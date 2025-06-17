# frozen_string_literal: true

require 'spec_helper'

require 'fileutils'
require 'excon'

RSpec.describe 'Puma', feature_category: :tooling do
  before_all do
    project_root = Rails.root.to_s
    config_lines = File.read(Rails.root.join('config/puma.example.development.rb'))
      .gsub('config.ru', File.join(__dir__, 'configs/config.ru'))
      .gsub('workers 2', 'workers 1')
      .gsub('/home/git/gitlab.socket', File.join(project_root, 'tmp/tests/puma.socket'))
      .gsub('on_worker_boot do', "on_worker_boot do\nFile.write('#{File.join(project_root, 'tmp/tests/puma-worker-ready')}', Process.pid)")
      .gsub(%r{/home/git(/gitlab)?}, project_root)
    config_path = File.join(project_root, 'tmp/tests/puma.rb')
    @socket_path = File.join(project_root, 'tmp/tests/puma.socket')

    File.write(config_path, config_lines)

    puma_path = begin
      Gem.bin_path('puma', 'puma')
    rescue StandardError
    end
    skip "Puma executable not found" unless puma_path

    cmd = %W[#{puma_path} -e test -C #{config_path} #{File.join(__dir__, 'configs/config.ru')}]

    env_vars = { 'DISABLE_PUMA_WORKER_KILLER' => '1' }
    spawn_options = { out: File::NULL, err: File::NULL }

    @puma_master_pid = spawn(env_vars, *cmd, spawn_options)
    wait_puma_boot!(@puma_master_pid, File.join(project_root, 'tmp/tests/puma-worker-ready'))
    WebMock.allow_net_connect!
  end

  %w[SIGTERM SIGKILL].each do |signal|
    it "maintains service availability when worker receives #{signal} in cluster mode" do
      # Get initial worker PID
      response = Excon.get('unix://', socket: @socket_path)
      expect(response.status).to eq(200)
      original_worker_pid = response.body.to_i
      expect(original_worker_pid).to be > 0

      send_signal_to_worker(signal)

      expect(service_recovers_with_new_worker?(original_worker_pid)).to eq(true)
    end
  end

  after(:all) do
    webmock_enable!
    Process.kill('TERM', @puma_master_pid) if @puma_master_pid
  rescue Errno::ESRCH
  end

  private

  def wait_puma_boot!(master_pid, ready_file)
    # We have seen the boot timeout after 2 minutes in CI so let's set it to 5 minutes.
    timeout = 5 * 60
    timeout.times do
      return if File.exist?(ready_file)

      pid = Process.waitpid(master_pid, Process::WNOHANG)
      raise "puma failed to boot: #{$?}" unless pid.nil?

      sleep 1
    end

    raise "puma boot timed out after #{timeout} seconds"
  end

  def send_signal_to_worker(signal)
    Excon.post("unix://?#{signal}", socket: @socket_path, read_timeout: 5)
  rescue Excon::Error::Socket
    # Expected when worker terminates
  rescue StandardError => e
    # Log but don't fail - the important thing is whether service recovers
    puts "Signal delivery may have failed: #{e.class} - #{e.message}"
  end

  def service_recovers_with_new_worker?(original_worker_pid)
    max_attempts = 60 # 1 minute total
    consecutive_successes_needed = 3
    consecutive_successes = 0

    max_attempts.times do |attempt|
      begin
        response = Excon.get('unix://', socket: @socket_path, read_timeout: 2)

        if response.status == 200
          new_worker_pid = response.body.to_i

          if new_worker_pid > 0 && new_worker_pid != original_worker_pid
            consecutive_successes += 1

            return true if consecutive_successes >= consecutive_successes_needed
          else
            # Still responding with same worker - reset counter
            consecutive_successes = 0
          end
        else
          consecutive_successes = 0
        end

      rescue StandardError => e
        consecutive_successes = 0
        puts "Attempt #{attempt + 1}: Service unavailable (#{e.class})" if attempt % 10 == 0
      end

      sleep 1
    end

    puts "Service did not recover with new worker within #{max_attempts} seconds"
    false
  end
end
