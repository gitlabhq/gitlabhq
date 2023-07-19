# frozen_string_literal: true

require 'spec_helper'

# For easier debugging set `PUMA_DEBUG=1`

RSpec.describe Gitlab::Cluster::Mixins::PumaCluster do
  before do
    stub_const('PUMA_STARTUP_TIMEOUT', 30)
  end

  context 'when running Puma in Cluster-mode' do
    using RSpec::Parameterized::TableSyntax

    where(:signal, :exitstatus, :termsig) do
      # executes phased restart block
      :USR1 | 140 | nil
      :USR2 | 140 | nil
      :INT | 140 | nil
      :HUP | 140 | nil

      # does not execute phased restart block
      :TERM | nil | 15
    end

    with_them do
      it 'properly handles process lifecycle' do
        with_puma(workers: 1) do |pid|
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

  def with_puma(workers:, timeout: PUMA_STARTUP_TIMEOUT)
    with_puma_config(workers: workers) do |puma_rb|
      cmdline = [
        "bundle", "exec", "puma",
        "-C", puma_rb,
        "-I", Rails.root.to_s
      ]

      IO.popen(cmdline) do |process|
        # wait for process to start:
        # [2123] * Listening on tcp://127.0.0.1:0
        wait_for_output(process, /Listening on/, timeout: timeout)
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

  def with_puma_config(workers:)
    Dir.mktmpdir do |dir|
      File.write "#{dir}/puma.rb", <<-EOF
        require './lib/gitlab/cluster/lifecycle_events'
        require './lib/gitlab/cluster/mixins/puma_cluster'

        workers #{workers}
        bind "tcp://127.0.0.1:0"
        preload_app!

        app -> (env) { [404, {}, ['']] }

        Puma::Cluster.prepend(#{described_class})

        mutex = Mutex.new

        Gitlab::Cluster::LifecycleEvents.on_before_blackout_period do
          mutex.synchronize do
            exit(140)
          end
        end

        # redirect stderr to stdout
        $stderr.reopen($stdout)
      EOF

      yield("#{dir}/puma.rb")
    end
  end

  def wait_for_output(process, output, timeout:)
    Timeout.timeout(timeout) do
      loop do
        line = process.readline
        puts "PUMA_DEBUG: #{line}" if ENV['PUMA_DEBUG']
        break if line.match?(output)
      end
    end
  end

  def consume_output(process)
    Thread.new do
      loop do
        line = process.readline
        puts "PUMA_DEBUG: #{line}" if ENV['PUMA_DEBUG']
      end
    rescue StandardError
    end
  end
end
