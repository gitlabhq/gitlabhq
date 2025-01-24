# frozen_string_literal: true

require 'spec_helper'

require 'fileutils'
require 'excon'

RSpec.describe 'Puma' do
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

    cmd = %W[puma -e test -C #{config_path} #{File.join(__dir__, 'configs/config.ru')}]
    @puma_master_pid = spawn({ 'DISABLE_PUMA_WORKER_KILLER' => '1' }, *cmd)
    wait_puma_boot!(@puma_master_pid, File.join(project_root, 'tmp/tests/puma-worker-ready'))
    WebMock.allow_net_connect!
  end

  %w[SIGTERM SIGKILL].each do |signal|
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
    webmock_enable!
    Process.kill('TERM', @puma_master_pid)
  rescue Errno::ESRCH
  end

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
